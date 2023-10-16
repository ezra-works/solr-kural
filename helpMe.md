## Get all commentary by columnist

- q: contentType:commentary AND columnist: "G.U Pope"

## Post document to core index

**Important** `bin/post` will flatten the document

- bin/post -c gettingstarted example/exampledocs/thirukural-intro.csv ;

**For Nested docs use POST API**

- curl -H "Content-Type: application/json" -X POST -d @kural-schema.json --url 'http://localhost:8983/solr/gettingstarted/schema?commit=true'

## Delete all docs in the core

- curl -X POST -H 'Content-Type: application/json' --data-binary '{"delete":{"query":"_:_" }}' http://localhost:8983/solr/gettingstarted/update?commit=true ;

## hint

- curl -X GET http://localhost:8983/solr/gettingstarted/config/initParams does not work for updating df as df does not have a name field

```
{
    "update-initparams":{
        "config":{
        "initParams":[{
        "path":"/update/**,/query,/select,/spell",
        "defaults":{
            "df":"other-name-1"
        }
        }]
        }
    }
}
```

## Docker commands

- docker volume ls
- docker volume inspect solr-on-cloud_data
- docker volume rm solr-on-cloud_data
- docker exec -it solr-on-cloud-solr-1 bash
- docker cp solr-on-cloud-solr-1:/var/solr/data/gettingstarted/conf/managed-schema.xml $(pwd)

adding new commit
