    Device
	    String DeviceID
	    String Token
	    String MetaData

    Question
	    Int QuestionId
	    String Question
	   
	Answer
		DateTime TimeStamp
		String DeviceId
		Int QuestionId
		Decimal Value
		Point X
		Point Y



Bool RegisterDevice(Device)

> This call register the device in the system, and is common only run once.

Question GetQuestion(DeviceId)
> This call gets the current question from the service for the specified device. 

Bool PostAnswer(Answer)
> This function accepts answers to quetsions.