## Protocols
Lua腳本協議的規範和定義

* 有部份協議沒有遵守Request和Respond的匹配,返回協議所用的ProcId也為ReqeustXXX，會逐步改動
* Respond協議必定會帶有兩個字段Result和ErrorCode用來表示操作結果，後續整理文檔后在協議定義中不再列舉出

## Client -> SA

##### RequestRegister/RespondRegister
帳號的註冊。SoulId的分配(系統內部)

```lua
{
  ProcId = "RequestRegister",
  Account = "String",
  Password = "String",
  Age = Number,
}
{
  ProcId = "RespondRegister",
  Account = "String",
  Password = "String", --不應該返回，後續會廢棄
  Age = Number,
  SoulId = Number, --返回這個字段也好像沒用，後續廢棄
  Result = Number,
  ErrorCode = Number,
}
```
##### RequestAuth/RespondAuth
根據註冊成功的帳號進行登錄驗證

```lua
{
  ProcId = "RequestAuth",
  Account = "String",
  Password = "String",
}
{
  ProcId = "RespondAuth",
  Account = "String",
  SoulId = Number, --返回該字段沒什麽必要，後續廢棄
  Result = Number,
  ErrorCode = Number,
}
```

##### RequestQuerySouler/RespondQuerySouler
查詢角色

```lua
{
  ProcId = "RequestQuerySouler",
}
{
  ProcId = "RespondQuerySouler",
  Result = Number,
  ErrorCode = Number,
  Souler = Table With Souler's Info(If Result == 1),
}
```

##### RequestCreateSouler/RespondCreateSouler
創建角色

```lua
{
  ProcId = "RequestCreateSouler",
  SoulInfo =
  {
    Sex = Number, --還未確定，可隨意
    Job = Number, --還未確定，可隨意
    Name = "String",
    GovId = Number, --角色所歸屬的Goverment
  },
}
{
  ProcId = "RespondCreateSouler",
  SoulInfo = The Same As Request And Addtional Data,
  Result = Number,
  ErrorCode = Number,
}
```

##### RequestSelectSouler/RespondSelectSouler
選擇角色

```lua
{
  ProcId = "RequestSelectSouler",
  --No Other Field
}
{
  ProcId = "RespondSelectSouler",
  GovId = Number, --暫時不知道有沒有必要返回給客戶端知道，後續可能廢棄
  Result = Number,
  ErrorCode = Number,
}
```

##### RequestArrival/RespondArrival
角色入境

```lua
--有大改動，暫時不記錄
```

##### RequestDeparture/RespondDeparture
角色離境

```lua
--有大改動，暫時不記錄
```
