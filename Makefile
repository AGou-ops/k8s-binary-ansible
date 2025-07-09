.PHONY: reset install startat help

default: install

uninstall:
	ansible-playbook 99.uninstall.yml -i inventory -e "flush_iptables=true enable_dual_stack_networks=false"

install:
	cd roles/addons/files && tar -czf charts.tar.gz charts && tar -czf grafana-dashboards-kubernetes.tar.gz grafana-dashboards-kubernetes && cd -
	@rm -rf certs || echo
	ansible-playbook 00.allinone.yml -i inventory --skip-tags=create_master_taint

download:
	ansible-playbook download.yml -vvv

upgrade: download
	ansible-playbook cluster.yml -i inventory -t install_kubectl,install_master,install_worker
	ansible-playbook cluster.yml -i inventory -t dis_master_config,dis_worker_config
	@while true; do \
	    read -p "输入需要重启服务的IP地址（Ctrl+C退出）: " IP; \
		ansible-playbook cluster.yml -i inventory -l $$IP -t restart_apiserver,restart_controller,restart_scheduler,restart_kubelet,restart_proxy,healthcheck; \
	done

startat:
	@if [ -z "$(task)" ]; then \
		echo "Error: You must specify a parameter for --start-at-task"; \
		exit 1; \
	fi
	ansible-playbook 00.allinone.yml -i inventory --skip-tags=create_master_taint --start-at-task="$(task)"

sync-charts:
	rsync -avz --delete roles/addons/files/charts 10.20.183.57:/etc/kubernetes/manifests

debug:
	ansible-playbook debug.yml -i inventory -vvv

registry:
	ssh 10.20.183.57 "nerdctl -n k8s.io exec local-registry registry garbage-collect -m /etc/docker/registry/config.yml && \
	cd /data && rm -f local-registry-data.tar.gz || echo ; \
	tar -cvf - local-registry | pigz -9 > /data/local-registry-data.tar.gz"
	mv -f ./roles/registry/files/local-registry-data.tar.gz{,.bak}
	scp 10.20.183.57:/data/local-registry-data.tar.gz ./roles/registry/files/local-registry-data.tar.gz
	ls -lh ./roles/registry/files/local-registry-data.tar.gz

pull-pki:
	scp -r 10.20.183.57:/root/.kube/config ~/.kube/config
	chmod 600 ~/.kube/config
	sed -i "s/localhost:9443/10.20.183.57:6443/" ~/.kube/config
	# kubectl konfig import --save ~/.kube/config.88

vpn: pull-pki
	kubevpn disconnect 0 || echo
	kubevpn connect --image registry.local:5000/naison/kubevpn:v2.6.0

etcd:
	@echo etcdctl --cacert=./certs/etcd-ca.pem --cert=./certs/10.20.183.57/etcd-server.pem --key=./certs/10.20.183.57/etcd-server.key --endpoints https://10.20.183.57:2379 endpoint status --cluster -w table

web-ui:
	@docker run -d --name ansible-webui -v `pwd`:/play -p 8000:8000 oxlorg/ansible-webui:latest

help:
	@echo "Usage:"
	@echo "  make                 # Run the install playbook (default)"
	@echo "  make uninstall           # Run the reset playbook"
	@echo "  make install         # Run the install playbook"
	@echo "  make upgrade         # Upgrade kubernetes components"
	@echo "  make startat task="xxx"   # Run the install playbook starting at a specific task"
