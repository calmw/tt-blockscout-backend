#### 位置

- apps/explorer/lib/explorer/chain.exs

```shell
  @spec total_supply :: non_neg_integer() | nil
  def total_supply do
#    supply_module().total() || 0
    Decimal.new("120000000.0")
end
```

#### 打包镜像

```shell

docker build --no-cache -t harbor.devops.tantin.com/web/blockscout-backend:20250929 .

docker push harbor.devops.tantin.com/web/blockscout-backend:20250929
```