Function payperview()
  print m.currentVideo
  payPerAmountDetail(m.currentVideo)

End Function

Sub payPerAmountDetail(video)
  total  = Val(tostr(video.payperviewprice))
  total  = total + Val("0.30")
  port = CreateObject("roMessagePort")
  screen = CreateObject("roParagraphScreen")
  screen.SetMessagePort(port)
  screen.AddHeaderText("Amount Detail")
  screen.AddParagraph(" Amount will be charged from your Good News Media account.")
  screen.AddParagraph("Amount :               $ "+tostr(video.payperviewprice))
  screen.AddParagraph("Transaction Fee :  $ 0.30")
  screen.AddParagraph("Total :                      $ "+ toFixed(total) )
  screen.AddButton(1, "continue")
  screen.AddButton(2, "back")
  screen.Show()
  if(m.currenScreen <> invalid)
    print "previous screen not closed"
    m.currenScreen.close()
  else
    print "Previous screen closed"
  endif
  while true
      msg = wait(0, screen.GetMessagePort())
      if type(msg) = "roParagraphScreenEvent"
          if msg.isScreenClosed()
              print "Screen closed"
              exit while
          else if msg.isButtonPressed()
              if(msg.GetIndex() = 1)
                print "I  am here"
                payPerViewPurchase(video.ID)
              endif
              print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
              exit while
          else
              print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
              exit while
          endif
      endif
  end while
End Sub

Sub payPerViewPurchase(videoID)
  dlg = createObject("roOneLineDialog")
  dlg.setTitle("Please wait...")
  dlg.showBusyAnimation()
  dlg.show()

  authtoken = RegRead("RegToken", "Authentication")
  url = Config().url + "/api/roku-media-pay-per-view/?video="+videoID
  print "this is url " url
  print "authtoken  "authtoken
  print "GetDeviceESN  "GetDeviceESN()
  http = NewHttp(url)
  http.Http.AddHeader("authtoken", authtoken)
  http.Http.AddHeader("deviceid", GetDeviceESN())

  rsp = ParseJSON(http.Http.GetToString())
  print rsp
  dlg.close()
  if(rsp = invalid)
      obj = {
        status: "failed"
        reason: "Payment failed!"
        message: "Your credit card not saved with Good New media."
      }
      ShowNotification(obj)
  else if(rsp.status = "success")
      m.isPurchaseCredit = true
      videoPlayer(videoID)
  else if(rsp.status = "failed")
      ShowNotification(rsp)
  endif

End Sub
