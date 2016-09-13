Function videoPlayer(videoID)
  this = {
    headers:""
    videoID:videoID
  }
  m.this = this
  m.videoID = videoID

  if checkUserRegistration() then
      videosubscription = checkVideoSubscription(m.videoID)
      print videosubscription
      if(videosubscription.status = "failed" and videosubscription.reason = "authorization")
            ShowNotification(videosubscription)
      else if(videosubscription.status = "failed" and videosubscription.reason = "notsubscribed")
            d = tostr(m.currentVideo.credit)
            print "this is d value=====" d
            if(d = "0")
              playVideoAfterAgree()
            else
              if(m.isPurchaseCredit <> invalid and m.isPurchaseCredit = true)
                playVideoAfterAgree()
              else
                videoPlayAgree()
              endif
            endif
      else if(videosubscription.status = "success")
            playVideoAfterAgree()
      else
      endif
  else
    doRegistration()
  endif

End Function

Function checkVideoSubscription(videoID) As Object
  authtoken = RegRead("RegToken", "Authentication")
  url = Config().url + "/api/check-video-subscription/?video="+videoID
  print "this is url " url
  print "authtoken  "authtoken
  http = NewHttp(url)
  if(checkUserRegistration())
    http.Http.AddHeader("authtoken", RegRead("RegToken", "Authentication"))
    http.Http.AddHeader("deviceid", GetDeviceESN())
  end if
  rsp = ParseJSON(http.Http.GetToString())
  print "This is check video response"; rsp
  return rsp
End Function


Function playVideoAfterAgree()
  m.isPurchaseCredit = false
  m.video =  getStreamData(m.videoID,m.this)
  if(m.video.status = "failed" and m.video.reason = "authorization")
      ShowNotification(m.video)
  else if(m.video.status = "failed" and m.video.reason = "insufficient")
      showPurchaseCreditScreen(m.video)
  else if(m.video.status = "success")
      if(m.video.hostType = "youtube")
          YoutubePlay(m.video,m.this)
      else
          playVideo(m.video,m.this)
      end if
  else
    obj = {
      status: "failed"
      reason: "unknown"
      message: "Something went wrong!"
    }
    ShowNotification(obj)
  endif

End Function

Function getStreamData(videoID,this) As object
  videoCredit = m.currentvideo.credit

  request = CreateObject("roUrlTransfer")
  authtoken = RegRead("RegToken", "Authentication")
  print "this is auth token:" authtoken
  print "this is auth token : " authtoken
  request.AddHeader("authtoken", authtoken)
  request.AddHeader("deviceid", GetDeviceESN())
  request.SetCertificatesFile("common:/certs/ca-bundle.crt")
  request.InitClientCertificates()
  port = CreateObject("roMessagePort")
  request.SetMessagePort(port)
  request.SetRequest("GET")
  request.SetUrl(Config().url+"/api/roku-media/?video="+VideoID)
  request.EnableCookies()
  request.EnableFreshConnection(true)
  if (request.AsyncGetToString())
      while (true)
          msg = wait(0, port)
          if (type(msg) = "roUrlEvent")
              code = msg.GetResponseCode()
              if (code = 200)
                  json = ParseJSON(msg.GetString())
                  print json
                  o                       = CreateObject("roAssociativeArray")
                  if(json.status = "failed")
                    return json
                  else
                    o.ID                    = json._id
                    o.ContentType           = json.type
                    o.Title                 = json.title
                    o.ShortDescriptionLine1 = json.description
                    o.ShortDescriptionLine2 = json.description
                    o.Description           = json.description
                    o.SDPosterUrl           = json.thumbnail
                    o.HDPosterUrl           = json.thumbnail
                    o.ReleaseDate           = json.createdAt
                    o.Name                  = json.name
                    o.Length                = json.length
                    o.hostType              = json.hostType

                    if(json.Stream.url = invalid)
                      o.Stream                = json.Stream
                    else
                      o.Stream                = json.Stream.url
                    endif
                    o.status                = json.status
                    this.headers            = msg.GetResponseHeadersArray()
                    return o
                  endif
              endif
          else if (event = invalid)
              request.AsyncCancel()
          endif
      end while
  endif
  return invalid

End Function

Function playVideo(video As Object,this)
  if(m.currenScreen <> invalid)
    print "previous screen not closed"
    m.currenScreen.close()
  else
    print "Previous screen not closed"
  endif

  'Public video link:
  'https://d3bxbu8i9alca1.cloudfront.net/C011-Unidentified.m3u8
  theurl = Video.Stream
  port = CreateObject("roMessagePort")
  screen = CreateObject("roVideoScreen")
  screen.EnableCookies()
  screen.SetCertificatesFile("common:/certs/ca-bundle.crt")
  screen.InitClientCertificates()
  video.Stream= {
    url : theurl,
    quality : true
    contented : "big-hls"
  }
  'For HLS Streaming We have to use below commented code
    'video.StreamBitrates = [0]
    'video.StreamUrls = [theurl]
    'video.StreamQualities = ["HD"]
    'video.StreamFormat = "hls"
  screen.SetContent(video)
  screen.SetMessagePort(port)
  screen.Show()
    while true
       msg = wait(0, port)
       if type(msg) = "roVideoScreenEvent" then
           print "showVideoScreen | msg = "; msg.GetMessage() " | index = "; msg.GetIndex()
           if msg.isScreenClosed()
               print "Screen closed"
               exit while
            else if msg.isStatusMessage()
                  print "status message: "; msg.GetMessage()
            else if msg.isPlaybackPosition()
                  print "playback position: "; msg.GetIndex()
                  nowpos = msg.GetIndex()
                RegWrite(episode.ContentId, nowpos.toStr())
            else if msg.isFullResult()
                  print "playback completed"
                  exit while
            else if msg.isPartialResult()
                  print "playback interrupted"
                  exit while
            else if msg.isRequestFailed()
                  print "request failed - error: "; msg.GetIndex();" - "; msg.GetMessage()
                  exit while
            end if
       end if
    end while
End Function

Function HlsStreamTestCode()
  thesetCooki = ""
    for each header in this.headers
      coki =  header.LookupCI("Set-Cookie")
        if(coki <> invalid)
          thesetCooki = coki
        endif
    end for
  req = CreateObject("roUrlTransfer")
  req.SetPort(CreateObject("roMessagePort"))
  req.SetCertificatesFile("common:/certs/ca-bundle.crt")
  req.AddHeader("Cookie", thesetCooki)
  req.InitClientCertificates()
  req.SetUrl(theurl)
  req.EnableCookies()
  req.EnableFreshConnection(true)
  if (req.AsyncGetToString())
     event = wait(30000, req.GetPort())
     if type(event) = "roUrlEvent"
        if (event.GetResponseCode() <> 200)
           'DisplayDialog("No Live Feed", "Please check back later.")
           print "roUrlEvent"
        endif

        headers = event.GetResponseHeadersArray()
     else if event = invalid
         print "AsyncGetToString timeout"
         req.AsyncCancel()
     else
         print "AsyncGetToString unknown event"
     endif
  endif

  print "This is headers count" headers.count()
  Location = ""
  for each header in headers
     val = header.LookupCI("Set-Cookie")
     val2 = header.LookupCI("Location")
     if (val <> invalid)
        if (val.Left(5) = "hdntl")
           hdntl = val.Left(Instr(1,val,";")-1)
        endif
        if (val.Left(6) = "_alid_")
           alid = val.Left(Instr(1,val,";")-1)
        endif
     endif
     if (val2 <> invalid)
       Location = val2
     endif
  end for

  print "This is set location:" Location

End Function

Function YoutubePlay(video As Object,this)
    print "Displaying video: "
    theurl = video.Name
    p = CreateObject("roMessagePort")
    video = CreateObject("roVideoScreen")
    video.setMessagePort(p)

    'bitrates  = [0]          ' 0 = no dots, adaptive bitrate
    'bitrates  = [348]    ' <500 Kbps = 1 dot
    'bitrates  = [664]    ' <800 Kbps = 2 dots
    'bitrates  = [996]    ' <1.1Mbps  = 3 dots
    'bitrates  = [2048]    ' >=1.1Mbps = 4 dots
    bitrates  = [0]

    'Swap the commented values below to play different video clips...
    'urls = ["http://video.ted.com/talks/podcast/CraigVenter_2008_480.mp4"]
    'qualities = ["HD"]
    'StreamFormat = "mp4"
    'title = "Craig Venter Synthetic Life"
    'srt = "file://pkg:/source/craigventer.srt"

    'urls = ["http://video.ted.com/talks/podcast/DanGilbert_2004_480.mp4"]
    'qualities = ["HD"]
    'StreamFormat = "mp4"
    'title = "Dan Gilbert asks, Why are we happy?"

    ' Apple's HLS test stream
    'urls = ["http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"]
    'qualities = ["SD"]
    'streamformat = "hls"
    'title = "Apple BipBop Test Stream"

    ' Big Buck Bunny test stream from Wowza
    urls = [theurl]
    qualities = ["SD"]
    streamformat = "hls"
    title = "Big Buck Bunny"
    srt = ""

    if type(args) = "roAssociativeArray"
        if type(args.url) = "roString" and args.url <> "" then
            urls[0] = args.url
        end if
        if type(args.StreamFormat) = "roString" and args.StreamFormat <> "" then
            StreamFormat = args.StreamFormat
        end if
        if type(args.title) = "roString" and args.title <> "" then
            title = args.title
        else
            title = ""
        end if
        if type(args.srt) = "roString" and args.srt <> "" then
            srt = args.StreamFormat
        else
            srt = ""
        end if
    end if

    videoclip = CreateObject("roAssociativeArray")
    videoclip.StreamBitrates = bitrates
    videoclip.StreamUrls = urls
    videoclip.StreamQualities = qualities
    videoclip.StreamFormat = StreamFormat
    videoclip.Title = title
    print "srt = ";srt
    if srt <> invalid and srt <> "" then
        videoclip.SubtitleUrl = srt
    end if

    video.SetContent(videoclip)
    video.show()

    lastSavedPos   = 0
    statusInterval = 10 'position must change by more than this number of seconds before saving

    while true
        msg = wait(0, video.GetMessagePort())
        if type(msg) = "roVideoScreenEvent"
            if msg.isScreenClosed() then 'ScreenClosed event
                print "Closing video screen"
                exit while
            else if msg.isPlaybackPosition() then
                nowpos = msg.GetIndex()
                if nowpos > 10000

                end if
                if nowpos > 0
                    if abs(nowpos - lastSavedPos) > statusInterval
                        lastSavedPos = nowpos
                    end if
                end if
            else if msg.isRequestFailed()
                print "play failed: "; msg.GetMessage()
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            endif
        end if
    end while
End Function
