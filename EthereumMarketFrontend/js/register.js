function registerAccount() {
  var userName = document.getElementById("userName").value;
  var userEmail = document.getElementById("userEmail").value;

  // コントラクトの呼び出し
  return contract.methods.registerAccount(userName, userEmail).send({ from: coinbase });
}