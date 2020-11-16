Log in to your AWS account. In AWS console select Cloudformation. Select the stack that you created. Click on "Resources" in the right pane :

<img src="../images/sc3.png"  width="700"/>

You should find clickable links for resources named "ApiGatewayRestApi" and "ApiKey". If you click on the physical ID of "ApiKey".

<img src="../images/sc1.png"  width="700"/>

Click on "Show". Make note of the API key that is displayed to you. Back in cloudformation, if you click on the physical ID of "ApiGatewayRestApi":

<img src="../images/sc2.png"  width="700"/>

Make note of the "Invoke URL" field. Replace the {stream-name} part in the url string with the name of the kinesis stream to send data to. 

Paste the API key and endpoint url into the appropriate fields in Constants.swift file. 
