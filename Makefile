.PHONY: reset install startat help

default: install

uninstall:
	ansible-playbook uninstall.yml -i inventory -e "flush_iptables=true enable_dual_stack_networks=false"

install:
	cd roles/addons/files && tar -czf charts.tar.gz charts && cd -
	@rm -rf certs || echo
	ansible-playbook 00.allinone.yml -i inventory --skip-tags=create_master_taint

download:
	ansible-playbook download.yml -vvv

startat:
	@if [ -z "$(task)" ]; then \
		echo "Error: You must specify a parameter for --start-at-task"; \
		exit 1; \
	fi
	ansible-playbook 00.allinone.yml -i inventory --skip-tags=create_master_taint --start-at-task="$(task)"

registry:
	ssh 10.20.183.80 "nerdctl -n k8s.io exec local-registry registry garbage-collect -m /etc/docker/registry/config.yml && \
	cd /data && rm -f local-registry-data.tar.gz || echo ; \
	tar -cvf - local-registry | pigz -9 > /data/local-registry-data.tar.gz"
	mv -f ./roles/registry/files/local-registry-data.tar.gz{,.bak}
	scp 10.20.183.80:/data/local-registry-data.tar.gz ./roles/registry/files/local-registry-data.tar.gz
	ls -lh ./roles/registry/files/local-registry-data.tar.gz

pull-pki:
	scp -r 10.20.183.80:/root/.kube/config ~/.kube/config
	# kubectl konfig import --save ~/.kube/config.88

vpn: pull-pki
	kubevpn disconnect 0 || echo
	kubevpn connect --image registry.local:5000/kubevpn:2.2.17

help:
	@echo "Usage:"
	@echo "  make                 # Run the install playbook (default)"
	@echo "  make uninstall           # Run the reset playbook"
	@echo "  make install         # Run the install playbook"
	@echo "  make startat task="xxx"   # Run the install playbook starting at a specific task"
