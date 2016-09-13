Function VideoDetailScreen(VideoID)
  content = getVideoDetail(VideoID)
  showVideoDetailScreen(content)
End Function

Function getVideoDetail(VideoID) as object
  dlg = createObject("roOneLineDialog")
  dlg.setTitle("Seaching...")
  dlg.showBusyAnimation()
  dlg.show()
  request = CreateObject("roUrlTransfer")
  request.SetCertificatesFile("common:/certs/ca-bundle.crt")
  request.AddHeader("X-Roku-Reserved-Dev-Id", "")
  if(checkUserRegistration())
    request.AddHeader("authtoken", RegRead("RegToken", "Authentication"))
    request.AddHeader("deviceid", GetDeviceESN())
  end if
  request.InitClientCertificates()
  port = CreateObject("roMessagePort")
  request.SetMessagePort(port)
  request.SetRequest("GET")
  request.SetUrl(Config().url+"/api/video-details/?video="+VideoID)
  if (request.AsyncGetToString())
      while (true)
          msg = wait(0, port)
          if (type(msg) = "roUrlEvent")
              code = msg.GetResponseCode()
              if (code = 200)
              dlg.close()
                  json = ParseJSON(msg.GetString())
                  o = CreateObject("roAssociativeArray")
                  o.ID                    = json._id
                  o.ContentType           = json.type
                  o.Title                 = json.title
                  o.ShortDescriptionLine1 = json.description
                  o.ShortDescriptionLine2 = json.description
                  o.Description           = json.description
                  o.SDPosterUrl           = json.thumbnail
                  o.HDPosterUrl           = json.thumbnail
                  o.ReleaseDate           = json.year
                  o.Length                = json.length
                  o.credit                = json.credit
                  o.payPerViewPrice       = json.per_view_price
                  o.subscribed            = json.subscribed
                  o.lengthHours           = json.lengthHours
                  o.Categories            = CreateObject("roArray", 10, true)
                  for each category in json.tags
                    o.Categories.push(category.name)
                  end for
                  m.currentVideo = o
                  return o
              endif
          else if (event = invalid)
              request.AsyncCancel()
          endif
      end while
  endif
  return invalid

End Function

Function showVideoDetailScreen(content)
  port = CreateObject("roMessagePort")
   springBoard = CreateObject("roSpringboardScreen")
   springBoard.SetBreadcrumbText("Video", "Detail")
   springBoard.SetMessagePort(port)
   springBoard.addbutton(1,"Play")
   if(tostr(content.payPerViewPrice) <> "0")
    if(content.subscribed <> true and checkUserRegistration())
      springBoard.addbutton(2,"$"+tostr(content.payPerViewPrice)+" pay per view (valid for 24 hours)")
    else if(checkUserRegistration() = 0)
      springBoard.addbutton(1,"$"+tostr(content.payPerViewPrice)+" pay per view (valid for 24 hours)")
    endif
   end if
   'content.ReleaseDate  = tostr(content.ReleaseDate).Split("-")[2]
   springBoard.SetStaticRatingEnabled(false)
   springBoard.SetContent(content)
   springBoard.Show()
   While True
       msg = wait(0, port)
       If msg.isScreenClosed() Then
           Return -1
       Elseif msg.isButtonPressed()
              if(msg.GetIndex() = 1)
                  videoPlayer(content.ID)
              else if(msg.GetIndex() = 2)
                  payperview()
              endif
           print "msg: "; msg.GetMessage(); "idx: "; msg.GetIndex()
       Endif
   End While
End Function
