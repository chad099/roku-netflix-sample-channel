' *********************************************************
' **  Roku Registration Demonstration App
' **  Support routines
' **  May 2009
' **  Copyright (c) 2009 Roku Inc. All Rights Reserved.
' *********************************************************

'******************************************************
'Show basic message dialog without buttons
'Dialog remains up until caller releases the returned object
'******************************************************

Function ShowPleaseWait(title As dynamic, text As dynamic) As Object

    port = CreateObject("roMessagePort")
    dialog = invalid

    'the OneLineDialog renders a single line of text better
    'than the MessageDialog.
    if text = ""
        dialog = CreateObject("roOneLineDialog")
    else
        dialog = CreateObject("roMessageDialog")
        dialog.SetText(text)
    endif

    dialog.SetMessagePort(port)

    dialog.SetTitle(title)
    dialog.ShowBusyAnimation()
    dialog.Show()
    return dialog
End Function

'******************************************************
'Retrieve text for connection failed
'******************************************************

Function GetConnectionFailedText() as String
    return "We were unable to connect to the service.  Please try again in a few minutes."
End Function

'******************************************************
'Show connection error dialog
'
'Parameter: retry t/f - offer retry option
'Return 0 = retry, 1 = back
'******************************************************

Function ShowConnectionFailedRetry() as dynamic
    Dbg("Connection Failed Retry")
    title = "Can't connect to video service"
    text  = GetConnectionFailedText()
    return ShowDialog2Buttons(title, text, "try again", "back")
End Function

'******************************************************
'Show Amzon connection error dialog with only an OK button
'******************************************************

Sub ShowConnectionFailed()
    'Dbg("Connection Failed")
    title = "Can't connect to video service"
    text  = GetConnectionFailedText()
    ShowErrorDialog(text, title)
End Sub

'******************************************************
'Show error dialog with OK button
'******************************************************

Sub ShowErrorDialog(text As dynamic, title=invalid as dynamic)
    ShowDialog1Button(title, text, "Done")
End Sub

'******************************************************
'Show 1 button dialog
'Return: nothing
'******************************************************

Sub ShowDialog1Button(title As dynamic, text As dynamic, but1 As String)
    if not isstr(title) title = ""
    if not isstr(text) text = ""

    Dbg("DIALOG1: ", title + " - " + text)

    port = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)

    dialog.SetTitle(title)
    dialog.SetText(text)
    dialog.AddButton(0, but1)
    dialog.Show()

    while true
        dlgMsg = wait(0, dialog.GetMessagePort())

        if type(dlgMsg) = "roMessageDialogEvent"
            if dlgMsg.isScreenClosed()
                print "Screen closed"
                return
            else if dlgMsg.isButtonPressed()
                print "Button pressed: "; dlgMsg.GetIndex(); " " dlgMsg.GetData()
                return
            endif
        endif
    end while
End Sub

'******************************************************
'Show 2 button dialog
'Return: 0=first button or screen closed, 1=second button
'******************************************************

Function ShowDialog2Buttons(title As dynamic, text As dynamic, but1 As String, but2 As String) As Integer
    if not isstr(title) title = ""
    if not isstr(text) text = ""

    Dbg("DIALOG2: ", title + " - " + text)

    port = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)

    dialog.SetTitle(title)
    dialog.SetText(text)
    dialog.AddButton(0, but1)
    dialog.AddButton(1, but2)
    dialog.Show()

    while true
        dlgMsg = wait(0, dialog.GetMessagePort())

        if type(dlgMsg) = "roMessageDialogEvent"
            if dlgMsg.isScreenClosed()
                print "Screen closed"
                dialog = invalid
                return 0
            else if dlgMsg.isButtonPressed()
                print "Button pressed: "; dlgMsg.GetIndex(); " " dlgMsg.GetData()
                dialog = invalid
                return dlgMsg.GetIndex()
            endif
        endif
    end while
End Function

Sub ShowNotification( message As dynamic) As Integer
    port = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)
    dialog.SetTitle(message.reason)
    dialog.SetText(message.message)
    dialog.AddButton(1, "Retry")
    dialog.AddButton(0, "Back")
    if(message.reason = "authorization")
      dialog.AddButton(2, "Authenticate")
    endif
    dialog.Show()
    while true
        dlgMsg = wait(0, dialog.GetMessagePort())
        if type(dlgMsg) = "roMessageDialogEvent"
          if(m.currenScreen <> invalid)
            print "previous screen not closed"
            m.currenScreen.close()
          else
            print "Previous screen closed"
          endif
          m.currenScreen = dialog
            if dlgMsg.isScreenClosed()
                print "Screen closed"
                return -1
            else if dlgMsg.isButtonPressed()
                if(dlgMsg.GetIndex() = 1 and message.reason = "authorization")
                    dialog.close()
                    return -1
                else if(dlgMsg.GetIndex() = 2 and message.reason = "authorization")
                    doRegistration()
                else if(dlgMsg.GetIndex() = 1 and message.reason="Payment failed!")
                    payPerAmountDetail(m.currentVideo)
                else if(dlgMsg.GetIndex() = 1)
                    showPurchaseCreditScreen(m.creditDetail)
                endif
                print "Button pressed: "; dlgMsg.GetIndex(); " " dlgMsg.GetData()
                dialog.close()
                return -1
            endif
        endif
    end while
End Sub

Sub videoPlayAgree()
    title = "Video play charge credit"
    print m.currentVideo.credit
    text = tostr(m.currentVideo.credit) +" Credits will be deducted for your account to watch this video. Please select 'I Agree' to continue or 'Back' to cancel. You will have 24 hours to finish watching this video once you select 'I Agree'."
    port = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)
    dialog.SetTitle(title)
    dialog.SetText(text)
    dialog.AddButton(1, "I Agree")
    dialog.AddButton(0, "Back")
    dialog.Show()
    while true
        dlgMsg = wait(0, dialog.GetMessagePort())
        if type(dlgMsg) = "roMessageDialogEvent"
            m.currenScreen = dialog
            if dlgMsg.isScreenClosed()
                print "Screen closed"
                exit while
            else if dlgMsg.isButtonPressed()
                print "Button Agreee: "; dlgMsg.GetIndex(); " " dlgMsg.GetData()
                if(dlgMsg.GetIndex() = 1)
                  playVideoAfterAgree()
                else
                  print "I AM HEREE"
                  dialog.close()
                  exit while
                endif
                exit while
            else
                print "Unknown event: "; dlgMsg.GetType(); " msg: "; dlgMsg.GetMessage()
                exit while
            endif
        endif
    end while
End Sub
