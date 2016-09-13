Function Config() As Object
  this = {
    liveUrl: "https://www.goodnewsmedia.net"
    stagingUrl: "http://staging.goodnewsmedia.net"
    searchIcon: "pkg:/images/search_icon.png"
    loginIcon: "pkg:/images/login_icon.png"
  }
  env = {
    url : "live"
  }
  if(env.url = "live")
    this.url = this.liveUrl
  else
    this.url = this.stagingUrl
  endif

  return this

End Function
