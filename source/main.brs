Function Main() as integer
  InitTheme()
  port = CreateObject("roMessagePort")
  grid = CreateObject("roGridScreen")
  grid.SetMessagePort(port)
  showArray = setupGrid(grid)
  grid.Show()
   while true
       msg = wait(0, port)
       if type(msg) = "roGridScreenEvent" then
           if msg.isScreenClosed() then
               return -1
           else if msg.isListItemFocused()
                grid.SetDescriptionVisible(true)
               print "Focused msg: ";msg.GetMessage();"row: ";msg.GetIndex();
               print " col: ";msg.GetData()
           else if msg.isListItemSelected()
              row = msg.GetIndex()
              selection = msg.getData()
              ID = showArray[row][selection].ID
              print ID
              if(ID = "search")
                  SearchScreen()
              else if (ID = "sign")
                  doRegistration()
              else if (ID = "logout")
                    deleteRegistrationToken()
                    print "i am logout"
                    grid.close()
              else
                  VideoDetailScreen(ID)
              endif
              print "Selected msg: ";msg.GetMessage();"row: ";msg.GetIndex();
              print " col: ";msg.GetData()
           endif
       endif
   end while

End Function

Function getData() As Object
    http  = NewHttp(Config().url+"/api/videos-browse/")
    rsp   = ParseJSON(http.Http.GetToString())
    if( rsp = invalid)
      return {}
    end if
    print "count response data : "rsp.count()
    return rsp
End Function

Function getVideos(catID) As Object
  print "category id :  "catID
  videos = CreateObject("roArray", 10, true)
  json   = m.mainvideos
  for each category in json
    if(catID = category._id)
      for each item in category.videos
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
    end if
  end for
  return videos
End Function

Function setupGrid(grid) As Object
  maindatas      =  getVideoCategoryList()
  m.mainvideos   =  getData()
  categories = CreateObject("roArray", 10, true)
  rowTitles = CreateObject("roArray", 10, true)
    for i = 0 to maindatas.count()-1
      videos = getVideos(maindatas[i].ID)
      if(videos.count() <> 0 or maindatas[i].ID = "search" or maindatas[i].ID = "sign")
        rowTitles.Push(maindatas[i].Title)
        maindatas[i].videos = videos
        categories.push(maindatas[i])
      end if
    end for

    'for each category in categories
      'rowTitles.Push(category.Title)
    'end for
  listposterArray = []
  listposterArray.push("square")
  for j = 0 to categories.count()-2
    listposterArray.push("portrait")
  end for
  print "This is list poster array"listposterArray.count()
  print "count of row titles : " rowTitles.count()
  grid.SetDisplayMode("scale-to-fill")
  grid.SetGridStyle("mixed-aspect-ratio")
  grid.SetupLists(rowTitles.Count())
  grid.SetListNames(rowTitles)
  showArray = []
  for i = 0 to categories.count()-1
    list = CreateObject("roArray", 10, true)
    if(categories[i].ID = "search")
      getobject = CreateObject("roArray", 10, true)
      object = {
        ID: "search"
        SDPosterUrl: Config().searchIcon
        HDPosterUrl: Config().searchIcon
        Description: "Search Videos"
        }
      getobject.push(object)

      if(checkUserRegistration())
      logout = {
        ID: "logout"
        SDPosterUrl: Config().loginIcon
        HDPosterUrl: Config().loginIcon
        Description: "Logout"
        }
        getobject.push(logout)
      endif

      list = getobject
    else
      list  = categories[i].videos
    endif
    showArray[i] = list
      grid.SetListPosterStyles(listposterArray)
      grid.SetContentList(i, list)
   end for
  return showArray
End Function

Function getVideoCategoryList() as object
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.AddHeader("X-Roku-Reserved-Dev-Id", "")
    request.InitClientCertificates()
    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    request.SetRequest("GET")
    request.SetUrl(Config().url+"/api/video-categories/")
    if (request.AsyncGetToString())
        while (true)
            msg = wait(0, port)
            if (type(msg) = "roUrlEvent")
                code = msg.GetResponseCode()
                print " this is response code:" code
                categories = CreateObject("roArray", 10, true)
                setting = {
                  ID:"search"
                  Title:""
                }
                categories.push(setting)
                if (code = 200)
                    json = ParseJSON(msg.GetString())
                    for each item in json
                        category = {
                            ID: item._id
                            Title: item.name
                        }
                        categories.push(category)
                    end for
                    return categories
                else
                    return categories
                endif
            else if (event = invalid)
                request.AsyncCancel()
            endif
        end while
    endif
    return invalid
End Function

Function getVideosFromCategory(categoryID) as object
  print "This is category id:"  categoryID
  request = CreateObject("roUrlTransfer")
  request.SetCertificatesFile("common:/certs/ca-bundle.crt")
  request.AddHeader("X-Roku-Reserved-Dev-Id", "")
  request.InitClientCertificates()
  port = CreateObject("roMessagePort")
  request.SetMessagePort(port)
  request.SetRequest("GET")
  request.SetUrl(Config().url+"/api/category-videos/?category="+categoryID)
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
