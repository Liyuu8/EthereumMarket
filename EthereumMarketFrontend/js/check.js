// メタマスクがインストールされているかチェックする
// メタマスクがインストールされている場合は、ウェブページを開いたときに、
// web3のグローバル変数にWeb3オブジェクトが自動的に代入される。
// メタマスクがインストールされていない場合、web3はundefinedとなる。

if (typeof web3 != "undefined") {
  web3js = new Web3(web3.currentProvider);
} else {
  alert("MetaMaskをインストールしてください。")
}

// メタマスクのアドレスを取得する
web3js.eth.getAccounts(function(err, accounts) {
  coinbase = accounts[0];
  console.log("coinbase is " + coinbase);
  if (typeof coinbase === "undefined") {
    alert("MetaMaskを起動してください。")
  }
});

// スマートコントラクトのアドレスを指定する
const address = "0x0C64ADE2e7291f6e43b9CC6DB562D4915001381a";

// スマートコントラクトのインスタンスを生成する
contract = new web3js.eth.Contract(abi, address);