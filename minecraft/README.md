Built off:
https://github.com/brettch/bedrock-server
https://github.com/Element-0/ElementZero

`docker-compose up -d` in `/dns` to start DNS server
`sudo chown -R 1000:1000 config development_resource_packs worlds` in `/minecraft`
`docker-compose up -d` in `/minecraft` to start minecraft server

`cp config/world_resource_packs.json worlds/bedrockLevel/world_resource_packs.json` to copy resource packs into generated world, and restart server
Update `ARG bedrockVersion=XXX` in Dockerfile to update bedrocker server editions
