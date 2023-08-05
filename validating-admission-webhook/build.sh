rm -r app/server.key &>/dev/null
rm -r app/server.crt &>/dev/null

cd certs/
sh certs.sh
cp server.key ../app/server.key
cp server.crt ../app/server.crt
cd ..

cd app/
image_tag=warden:v1
docker build -t $image_tag .
kind load docker-image $image_tag
cd ..

cd kubernetes/
sed -i "s/image:\s.*/image: $image_tag/g" deploy.yaml
sed -i "s/caBundle:\s.*/caBundle: $(echo $(cat ../certs/ca.crt | base64 -w -0))/g" webhook.yaml
kubectl delete -f . --force --grace-period=0 &>/dev/null
kubectl apply -f deploy.yaml
kubectl apply -f webhook.yaml
cd ..
