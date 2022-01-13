# Kubernetes Pod Admission Controller

This is a repo with a Golang implementation of a pod admission controller for Kubernetes. The role of this pod admission controller is to enforce a labeling standard since it will validate (via a Validating Webhook) the existence of certain pre-defined labels, regardless of their value.

Feel free to use, but at your own risk.

## Proposed solution

"In a nutshell, Kubernetes admission controllers are plugins that govern and enforce how the cluster is used. They can be thought of as a gatekeeper that intercept (authenticated) API requests and may change the request object or deny the request altogether. The admission control process has two phases: the mutating phase is executed first, followed by the validating phase. Consequently, admission controllers can act as mutating or validating controllers or as a combination of both." (as per [Kubernetes Admission Controller Guide](https://kubernetes.io/blog/2019/03/21/a-guide-to-kubernetes-admission-controllers/))

Below, you can find a diagram describing the two phases of admission control.

![alt text](/docs/admission-controller-phases.png)

In order to gain control over the validation of pods' labels (thus enforcing a labeling strategy), it was necessary to implement a validating webhook. The respective action is obtained from a REST endpoint (a webhook) of a service running inside the cluster. This approach decouples the admission controller logic from the Kubernetes API server, thus allowing users to implement custom logic to be executed whenever resources are created, updated, or deleted in a Kubernetes cluster.

This was achieved by implementing an Admission Controller in Golang, using popular Kubernetes libraries (for example, [k8s.io/*](https://pkg.go.dev/search?q=k8s.io)), making it easy to leverage the interaction with the Kubernetes API Server. The Admission Controller is represented by a simple webserver which handles requests from the Validating Webhook on "/validate" path and verifies the existence of labels (which are defined when the Admission Controller is deployed as an argument).

It is important to mention that all the requests should be HTTPS, since the Kubernetes API Server supports only HTTPS communication. For this, it is necessary to use TLS encryption via certificates. In order to implement this easily and dynamically, it is recommended to use a solution such as [Cert Manager](https://cert-manager.io/docs/) which is a fully managed, open source, X.509 certificate solution for issuers within the cluster. (this solution is demonstrated in the [helm directory](/helm)).

## How to build the Admission Controller

```
go mod tidy
go build -o ./admission-controller
docker build .
```

## How tu use the Admission Controller

There are 4 important arguments:

- *--tls-cert* - path to the certificate for TLS (*example: /etc/certs/tls.crt*)
- *--tls-key* - path to the private key file for TLS (*example: /etc/certs/tls.key*)
- *--labels* - comma-separated list of mandatory labels; if the mentioned labels are not present, the Pod will not be created (*example: test1,test2*)
- *--port* - port to expose the webserver (*example: 443*)

The command to start the Admission Controller webserver:
```
admission-controller --tls-cert <path-to-tls-cert> --tls-key <path-to-tls-key> --labels <label1,label2,etc> --port <port-number>
```

The first 3 arguments are mandatory, while the port has a default value of 443.

The webserver alone is not enough in order to implement the Validating Webhook mechanism, since you should also create a Kubernetes object called [ValidatingWebhookConfiguration](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.23/#validatingwebhookconfiguration-v1-admissionregistration-k8s-io) which is responsible with implementing the Validating Admission Webhook mechanism (an example can be found [here](/helm/templates/validatingwebhookconfiguration.yaml)).

## How to deploy and test a functional solution

In order to deploy the Pod Admission Controller easily, it is recommended to use the helm chart available [here](/helm).

In the [values.yaml](/helm/values.yaml) file, you can customize the image used by the Pod Admission Controller, its starting options, resources, affinity, tolerations and, very importantly, the namespace where cert-manager is deployed (this solution is dependent on cert-manager - this is necessary since the CA certificate should be deployed in the same namespace as cert-manager).

To deploy the cert-manager helm chart:
```
helm repo add jetstack https://charts.jetstack.io
bash helper/install_certmanager.sh
```
Afterwards, to install the admission-controller chart:
```
cd helper
bash install_admission_controller.sh
```
To test the Pod Admission Controller, it is recommended to try deploying a simple pod with different labels, as pointed out in the [test_manifest.yaml](/helper/test_manifest.yaml).
```
kubectl apply -f helper/test_manifest.yaml -n <preferred namespace>
```
## Sources and special thanks

https://github.com/trstringer/kubernetes-validating-webhook

https://github.com/douglasmakey/admissioncontroller
