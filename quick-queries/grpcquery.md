# cl position_id query via grpc

## for non-tls server

`grpcurl -plaintext -H "Content-Type: application/grpc" -d '{"position_id": "<ID>"}' grpc.osmosis.zone:9090 osmosis.concentratedliquidity.v1beta1.Query/PositionById`


## for tls-enabled server—

### grab cert info 
`openssl s_client -connect <grpc_server>`

### copy everything between and including these lines—

```
-----BEGIN CERTIFICATE-----
<STUFF>
-----END CERTIFICATE-----
```

### paste to file like `cert.pem` and use with `-cacert` flag

`grpcurl -H "Content-Type: application/grpc" -d '{"position_id": "<ID>"}' -cacert /path/to/cert.pem -servername osmosis-grpc.lavenderfive.com -v     osmosis-grpc.lavenderfive.com:443 osmosis.concentratedliquidity.v1beta1.Query/PositionById`
<br>

<br>

#### protobeaf for context
```
  // PositionById returns a position with the given id.
  rpc PositionById(PositionByIdRequest) returns (PositionByIdResponse) {
    option (google.api.http).get =
        "/osmosis/concentratedliquidity/v1beta1/position_by_id";
  }
```
