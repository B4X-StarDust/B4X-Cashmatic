' B4J Example - REST API CALL

Sub Process_Globals
    Private fx As JFX
    Private MainForm As Form
    
    Private apiUrl As String = "https://127.0.0.1:50301/api"
    Private bearerToken As String = ""
End Sub

Sub AppStart (Form1 As Form, Args() As String)
    MainForm = Form1
    MainForm.Show
    
    Dim ip As String = InputBox("IP ADDRESS (Empty if using Simulator):", "IP", "")
    
    If ip <> "" Then
        apiUrl = "https://" & ip & ":50301/api"
    End If
    
    LogMsg("IP ADDRESS SET: " & apiUrl)
    
    Do While True
        Dim cmd As String = InputBox("1=Login, 2=Payment, 3=Cancel, 4=StartRefill, 5=StopRefill, 6=Active, 7=Quit", "Command", "")
        
        Select cmd
            Case "1"
                Dim username As String = InputBox("USERNAME:", "Login", "")
                Dim password As String = InputBox("PASSWORD:", "Login", "")
                Login(username, password)
                
            Case "2"
                Dim amount As Int = 0
                Do While amount <= 0
                    amount = InputBox("AMOUNT IN CENTS:", "Payment", "0")
                Loop
                Payment(amount)
                
            Case "3"
                CancelPayment
                
            Case "4"
                StartRefill
                
            Case "5"
                StopRefill
                
            Case "6"
                ActiveTransaction
                
            Case "7"
                LogError("QUITTING")
                Exit
                
            Case Else
                LogError("Command not found")
        End Select
    Loop
End Sub

Sub SendCommand(command_url As String, content As String) As String
    Dim job As HttpJob
    job.Initialize("job", Me)
    
    job.PostString(apiUrl & command_url, content)
    job.GetRequest.SetContentType("application/json")
    
    If command_url <> "/user/Login" Then
        job.GetRequest.SetHeader("Authorization", "Bearer " & bearerToken)
    End If
    
    Wait For (job) JobDone(job As HttpJob)
    
    If job.Success Then
        LogMsg("RESPONSE: " & job.Response.StatusCode)
        Dim res As String = job.GetString
        Log(res)
        job.Release
        Return res
    Else
        LogError(job.ErrorMessage)
        job.Release
        Return ""
    End If
End Sub

Sub Login(username As String, password As String)
    Dim m As Map
    m.Initialize
    m.Put("username", username)
    m.Put("password", password)
    
    Dim json As JSONGenerator
    json.Initialize(m)
    
    Dim response As String = SendCommand("/user/Login", json.ToString)
    
    If response = "" Then
        LogError("Failed sending the request")
        Return
    End If
    
    Dim parser As JSONParser
    parser.Initialize(response)
    Dim root As Map = parser.NextObject
    
    Dim data As Map = root.Get("data")
    bearerToken = data.Get("token")
    
    LogMsg("- BEARER TOKEN SAVED")
End Sub

Sub Payment(amount As Int)
    Dim m As Map
    m.Initialize
    m.Put("amount", amount)
    
    Dim json As JSONGenerator
    json.Initialize(m)
    
    SendCommand("/transaction/StartPayment", json.ToString)
End Sub

Sub CancelPayment
    SendCommand("/transaction/CancelPayment", "{}")
End Sub

Sub StartRefill
    SendCommand("/transaction/StartRefill", "{}")
End Sub

Sub StopRefill
    SendCommand("/transaction/StopRefill", "{}")
End Sub

Sub ActiveTransaction
    SendCommand("/device/ActiveTransaction", "{}")
End Sub

Sub LogMsg(msg As String)
    Log(msg)
End Sub

Sub LogError(msg As String)
    Log("ERROR: " & msg)
End Sub
