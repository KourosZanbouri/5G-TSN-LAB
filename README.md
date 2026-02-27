# Cloud-Native 5G-TSN Testbed

## Automated Deployment of a Deterministic 5G Core on Kubernetes

##  Project Overview

This repository contains the **Infrastructure-as-Code (IaC)** and automation pipelines required to deploy a fully functional **5G Standalone (SA) Core Network** on a public cloud environment (AWS).

Designed for **Time-Sensitive Networking (TSN)** research, this testbed solves specific challenges related to running deterministic networking protocols in containerized environments, including **SCTP/GTP kernel module injection**, **persistent storage for subscriber data**, and **Cloud-Native orchestration**.

##  Architecture

The system is built on a 3-node Kubernetes cluster orchestrated via Terraform and Ansible.

-   **Infrastructure:** AWS EC2 instances (Master + 2 Workers) provisioned via **Terraform**.
    
-   **Configuration:** Automated OS hardening and 5G Kernel module loading (`sctp`, `gtp`, `8021q`) via **Ansible**.
    
-   **Orchestration:** **Kubernetes (Kubeadm)** with Flannel CNI.
    
-   **Application:** **Open5GS** (AMF, SMF, UPF) deployed via **Helm Charts**.
    
-   **Storage:** Dynamic Local Path Provisioning for MongoDB state persistence.
    

----------

##  Deployment Guide

## Prerequisites

-   AWS CLI configured with credentials.
    
-   Terraform (v1.5+) & Ansible (v2.10+) installed locally.
    
-   `kubectl` and `helm` installed locally.
    

## Step 1: Provision Infrastructure (Terraform)

We use Terraform to treat the infrastructure as code, spinning up the Virtual Private Cloud (VPC), Security Groups (firewalls), and EC2 instances.

Bash

```
cd terraform
# Initialize and Apply (Provisions 3 VMs on AWS)
terraform init
terraform apply -auto-approve

```

-   **Output:** Generates `hosts.ini` with public IP addresses for the Master and Worker nodes.
    

## Step 2: Configure Cluster & Kernel (Ansible)

This playbook transforms raw Ubuntu servers into a 5G-ready Kubernetes cluster. It specifically handles the **"Missing Kernel Module"** issue on AWS by injecting `linux-modules-extra`.

Bash

```
cd ansible
# Run the automation playbook
ansible-playbook site.yml

```

-   **Key Task:** Loads `sctp` and `gtp` modules required for the N2 and N3 interfaces.
    
-   **Key Task:** Installs `containerd`, `kubeadm`, and initializes the Control Plane.
    

## Step 3: Deploy 5G Core (Helm)

We deploy the Open5GS microservices using the GitOps approach, cloning the source charts for maximum control.


```
# 1. Clone the charts
git clone https://github.com/Gradiant/5g-charts.git
cd 5g-charts

# 2. Update Dependencies (MongoDB)
helm dependency update ./charts/open5gs

# 3. Deploy to Kubernetes (Disabling 4G/EPC for pure 5G SA)
kubectl create namespace open5gs
helm install my-5g-core ./charts/open5gs \
  --namespace open5gs \
  --set epc.mme.enabled=false \
  --set epc.hss.enabled=false \
  --set epc.sgwc.enabled=false \
  --set epc.sgwu.enabled=false

```

----------

##  Verification

To verify the 5G Core is live and listening for Radio (gNB) connections via SCTP:

Bash

```
# Check if all pods are Running
kubectl get pods -n open5gs

# Check AMF logs for SCTP binding
kubectl logs -n open5gs -l app.kubernetes.io/component=amf | grep sctp

```

**Expected Output:**

> `[sctp] server (10.42.x.x:38412) bound`

----------

## 🚧 TSN Implementation (Under Development)

This section details the ongoing work to enable **Time-Sensitive Networking (TSN)** features on top of the 5G Core.

## 1. Traffic Isolation (Multus CNI)

-   **Goal:** Separate Control Plane traffic (Kubernetes/Flannel) from User Plane traffic (5G Data).
    
-   **Implementation:** Integrating **Multus CNI** to attach a secondary network interface (`net1`) to the UPF pod.
    
-   **Status:** _In Progress_ - Defining `NetworkAttachmentDefinition` for Macvlan bridging.
    

## 2. Deterministic Scheduling (Traffic Control)

-   **Goal:** Emulate IEEE 802.1Qbv (Time-Aware Shaper) behavior in a virtualized environment.
    
-   **Implementation:** Using Linux `tc-taprio` (Traffic Control) to enforce strict priority queuing for TSN flows.
    
-   **Tools:** [ottoblep/tsn-5g-testbench](https://github.com/ottoblep/tsn-5g-testbench) for traffic generation and latency measurement.
    

## 3. PTP Synchronization

-   **Goal:** Achieve microsecond-level clock synchronization between nodes.
    
-   **Implementation:** Deploying `linuxptp` (PTP4l) DaemonSets on all Kubernetes nodes to synchronize system clocks via software PTP.
    

----------



## 🛠️ Tech Stack
| Component | Technology |
| :--- | :--- |
| **Cloud Provider** | AWS (EC2, VPC) |
| **IaC** | Terraform |
| **Configuration** | Ansible |
| **Container Runtime** | Docker / Containerd |
| **Orchestration** | Kubernetes (Kubeadm) |
| **5G Core** | Open5GS |
| **Networking** | Flannel (Default), Multus (TSN) |
| **TSN Tools** | Linux Traffic Control (`tc`), PTP4l |


## TSN Implementation (Under Development)

This section details the ongoing work to enable **Software-Defined TSN** features on top of the 5G Core using a pure Linux networking approach.

## 1. Traffic Isolation via Multus CNI

-   **Goal:** Separate "Best Effort" Control Plane traffic (Kubernetes API, Flannel) from "Critical" User Plane traffic (5G Data).
    
-   **Implementation:**
    
    -   Deploying **Multus CNI** to attach a secondary network interface (`net1`) to the UPF pod.
        
    -   Configuring `NetworkAttachmentDefinition` to bridge the secondary interface directly to the host network, bypassing the default overlay network (VXLAN) to reduce jitter.
        

## 2. 802.1Qbv Emulation (Time-Aware Shaper)

-   **Goal:** Emulate the behavior of a TSN switch (Gate Control List) in a virtualized environment.
    
-   **Implementation:**
    
    -   Using the Linux **Traffic Control (`tc`)** subsystem with the `taprio` qdisc (Queueing Discipline).
        
    -   Configuring strict priority schedules on the egress interface of the Worker Nodes to prioritize 5G User Plane traffic over background system noise.
        

## 3. Software Clock Synchronization

-   **Goal:** Achieve microsecond-level synchronization between the Master and Worker nodes without hardware PTP support.
    
-   **Implementation:**
    
    -   Deploying `linuxptp` (PTP4l) as a DaemonSet in **Software Mode**.
        
    -   Configuring the Master Node as the Grandmaster Clock and Worker Nodes as slaves to synchronize system clocks for coordinated packet scheduling.