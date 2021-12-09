# pod-admission-controller

Admission controller test repository.

Feel free to use, but at your own risk.

How to use:

```
go mod tidy
go build -o ./admission-controller
docker build -t admission-controller:0.0.1 .
```

Sources:

https://github.com/trstringer/kubernetes-validating-webhook

https://github.com/douglasmakey/admissioncontroller
