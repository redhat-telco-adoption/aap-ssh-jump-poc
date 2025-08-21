1. Get an Automation Hub Token
2. Export the automation hub token
```
export PAH_TOKEN=<your token>
```
3. Build the execution environment
```
ansible-builder build -t custom-ee:latest --container-runtime podman --build-arg=ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN=$PAH_TOKEN 
```