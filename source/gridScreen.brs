Function GridScreen(keyword)
    port = CreateObject("roMessagePort")
    grid = CreateObject("roGridScreen")
    grid.SetMessagePort(port)
    rowTitles = CreateObject("roArray", 10, true)
    rowTitles.Push("Search Results : ")
    grid.SetupLists(rowTitles.Count())
    grid.SetListNames(rowTitles)
    grid.SetGridStyle("flat-portrait")
    for j = 0 to 0
      list = CreateObject("roArray", 10, true)
      list  = getSearchContent(keyword)
      grid.SetContentList(j, list)
     end for
     grid.Show()
     while true
         msg = wait(0, port)
         if type(msg) = "roGridScreenEvent" then
             if msg.isScreenClosed() then
                 return -1
             elseif msg.isListItemFocused()
                 print "Focused msg: ";msg.GetMessage();"row: ";msg.GetIndex();
                 print " col: ";msg.GetData()
             elseif msg.isListItemSelected()
                 VideoDetailScreen(list[msg.GetData()].id)
                 print "Selected msg: ";msg.GetMessage();"row: ";msg.GetIndex();
                 print " col: ";msg.GetData()
             endif
         endif
     end while
End Function


Function getSearchContent(keyword)
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.AddHeader("X-Roku-Reserved-Dev-Id", "")
    request.InitClientCertificates()
    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    request.SetRequest("GET")
    dlg = createObject("roOneLineDialog")
    dlg.setTitle("Seaching...")
    dlg.showBusyAnimation()
    dlg.show()
    keyword = request.UrlEncode(keyword)
    request.SetUrl(Config().url+"/api/search-videos/?keyword="+keyword)
    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, port)
            if (type(msg) = "roUrlEvent")
            dlg.close()
                code = msg.GetResponseCode()
                print "I AM RESPONSE CODE";code
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
