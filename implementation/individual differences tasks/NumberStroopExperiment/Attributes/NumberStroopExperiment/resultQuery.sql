SELECT fileName, listNumber, assignmentId, hitId, workerId, origin, timestamp, partId, questionId, answer::TEXT, (data->>'item') as item, (data->>'trialType') as trialType, (data->>'totalDigits') as totalDigits, id FROM (
	(SELECT * FROM Results WHERE experimentType='NumberStroopExperiment') as tmp1
	LEFT OUTER JOIN Questions USING (QuestionId)
	LEFT OUTER JOIN Groups USING (PartId)
) as tmp
WHERE LingoExpModelId = 1042
ORDER BY partId, workerId