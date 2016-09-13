Function SearchScreen() as Void
    print "start"
    'toggle the search suggestions vs. search history behavior
    'this allow you to generate both versions of the example below
    displayHistory = true
    history = CreateObject("roArray", 1, true)
    'prepopulate the search history with sample results
    port = CreateObject("roMessagePort")
    screen = CreateObject("roSearchScreen")
    'commenting out SetBreadcrumbText() hides breadcrumb on screen
    screen.SetBreadcrumbText("", "search")
    screen.SetMessagePort(port)
    if displayHistory
        screen.SetSearchTermHeaderText("Recent Searches:")
        screen.SetSearchButtonText("search")
        screen.SetClearButtonText("clear history")
        screen.SetClearButtonEnabled(true) 'defaults to true
        screen.SetSearchTerms(history)
    else
        screen.SetSearchTermHeaderText("Suggestions:")
        screen.SetSearchButtonText("search")
        screen.SetClearButtonEnabled(false)
    endif
    print "Doing show screen..."
    screen.Show()
    print "Waiting for a message from the screen..."
    ' search screen main event loop
    done = false
    videoDetail = false

    while done = false
        msg = wait(0, screen.GetMessagePort())
        if type(msg) = "roSearchScreenEvent"
            if msg.isScreenClosed()
                print "screen closed"
                done = true
            else if msg.isCleared()
                print "search terms cleared"
                history.Clear()
            else if msg.isPartialResult()
                print "partial search: "; msg.GetMessage()
                videoDetail = true
                partialSearchResult(msg.GetMessage(),screen,history)
                if not displayHistory
                    screen.SetSearchTerms((msg.GetMessage()))
                endif
            else if msg.isFullResult()
                print "full search: "; msg.GetMessage()
                GridScreen(msg.GetMessage())
                if displayHistory
                    screen.AddSearchTerm(msg.GetMessage())
                end if
                'uncomment to exit the screen after a full search result:
                'done = true
                videoDetail = false
            else if msg.IsButtonInfo()
                    print "I am button info"
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            endif
        endif
    endwhile
    print "Exiting..."
End Function


Function partialSearchResult(keyword,screen,history)
  results = searchVideos(keyword)
  screen.SetSearchTerms(" ")
  screen.SetSearchTermHeaderText("Partial Search results:")
  for each item in results
      screen.AddSearchTerm(item.Title)
  end for

End Function

Function searchVideos(keyword)
  request = CreateObject("roUrlTransfer")
  request.SetCertificatesFile("common:/certs/ca-bundle.crt")
  request.AddHeader("X-Roku-Reserved-Dev-Id", "")
  request.InitClientCertificates()
  port = CreateObject("roMessagePort")
  request.SetMessagePort(port)
  request.SetRequest("GET")
  request.SetUrl(Config().url+"/api/search-videos/?keyword="+keyword)
  if (request.AsyncGetToString())
      while (true)
          msg = wait(0, port)
          if (type(msg) = "roUrlEvent")
              code = msg.GetResponseCode()
              if (code = 200)
                  videos = CreateObject("roArray", 10, true)
                  json = ParseJSON(msg.GetString())
                  for each item in json
                      video = {
                          ID: item._id
                          Title: item.title
                          ContentType: item.type
                          Description: item.description
                          Name: item.name
                          SDPosterUrl: item.thumbnail
                          HDPosterUrl: item.thumbnail
                          ShortDescriptionLine1: item.description
                          ShortDescriptionLine2: item.description
                      }
                      videos.push(video)
                  end for
                  return videos
              endif
          else if (event = invalid)
              request.AsyncCancel()
          endif
      end while
  endif
  return invalid

End Function
