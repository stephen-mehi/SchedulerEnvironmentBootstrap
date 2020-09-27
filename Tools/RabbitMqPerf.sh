instance=rabbitmqdef
username=$(kubectl get secret ${instance}-rabbitmq-admin --namespace rabbitmq -o jsonpath="{.data.username}" | base64 --decode)
password=$(kubectl get secret ${instance}-rabbitmq-admin --namespace rabbitmq -o jsonpath="{.data.password}" | base64 --decode)
service=${instance}-rabbitmq-client
kubectl run perf-test --image=pivotalrabbitmq/perf-test --namespace rabbitmq -- --uri "amqp://${username}:${password}@${service}"
kubectl logs -f perf-test -n rabbitmq