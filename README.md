# connectatron
connect to a virtual cluster in a managed runtime

## Usage for hosted:
```
# current context should be host cluster

# with account id or account name
./connectatron $accountIdOrName
```

## Usage for hybrid:
```
# current context should be the runtime cluster

./connectatron ns $runtimeNamespace
```

# Stop existing port-forward
```
./connectatron stop
```