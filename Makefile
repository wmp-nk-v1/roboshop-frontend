.PHONY: build run docker-build argocd-deploy clean

ECR_REPO = 293222827824.dkr.ecr.us-east-1.amazonaws.com/roboshop-frontend

build:
	npm install && npm run build

run:
	npm run dev

docker-build:
	aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 293222827824.dkr.ecr.us-east-1.amazonaws.com
	docker build -t $(ECR_REPO):$(image_tag) .
	trivy image $(ECR_REPO):$(image_tag) -s CRITICAL,HIGH --ignore-unfixed
	docker push $(ECR_REPO):$(image_tag)

argocd-deploy:
	argocd login $(argocd_server) --skip-test-tls --username admin --password $(argocd_admin_password)
	argocd app create roboshop-frontend --sync-policy auto --upsert \
		--repo https://github.com/nikkaushal/roboshop-helm-v1.git \
		--path . \
		--dest-server https://kubernetes.default.svc \
		--dest-namespace roboshop \
		--helm-set services.frontend.tag=$(image_tag) \
		--values values/roboshop-frontend.yml

clean:
	rm -rf node_modules .next
