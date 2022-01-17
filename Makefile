# Copyright 2022 VMware. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

REQUIRED_BINARIES := imgpkg kbld ytt
CORE_OCI_IMAGE := ghcr.io/alexandreroman/gitops-with-tanzu-core:stable
MONITORING_OCI_IMAGE := ghcr.io/alexandreroman/gitops-with-tanzu-monitoring:stable
REPO_OCI_IMAGE := ghcr.io/alexandreroman/gitops-with-tanzu-repo:stable

check-carvel:
	$(foreach exec,$(REQUIRED_BINARIES),\
		$(if $(shell which $(exec)),,$(error "'$(exec)' not found. Carvel toolset is required. See instructions at https://carvel.dev/#install")))

lock: check-carvel # Updates image lock files and synchronize repository.
	cd pkg/core && rm -f .imgpkg/images.yml && kbld -f config --imgpkg-lock-output .imgpkg/images.yml
	cd pkg/monitoring && rm -f .imgpkg/images.yml && kbld -f config --imgpkg-lock-output .imgpkg/images.yml
	ytt -f pkg/core/metadata.yaml -f pkg/core/package.yaml > repo/packages/core.yaml
	ytt -f pkg/monitoring/metadata.yaml -f pkg/monitoring/package.yaml > repo/packages/monitoring.yaml

push: check-carvel lock # Build and push packages.
	cd pkg/core && imgpkg push --bundle $(CORE_OCI_IMAGE) --file .
	cd pkg/monitoring && imgpkg push --bundle $(MONITORING_OCI_IMAGE) --file .
	mkdir -p repo/.imgpkg
	rm -f repo/.imgpkg/images.yml && kbld -f repo/packages --imgpkg-lock-output repo/.imgpkg/images.yml
	cd repo && imgpkg push --bundle $(REPO_OCI_IMAGE) --file .
