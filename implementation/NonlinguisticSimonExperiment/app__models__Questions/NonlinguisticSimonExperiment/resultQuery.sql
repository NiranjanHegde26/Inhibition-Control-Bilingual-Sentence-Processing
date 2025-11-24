SELECT fileName, listNumber, assignmentId, hitId, workerId, origin, timestamp, partId, questionId, answer::TEXT, (data->>'item') as item, (data->>'screenPosition') as screenPosition, (data->>'trialType') as trialType, id FROM (
	(SELECT * FROM Results WHERE experimentType='NonlinguisticSimonExperiment') as tmp1
	LEFT OUTER JOIN Questions USING (QuestionId)
	LEFT OUTER JOIN Groups USING (PartId)
) as tmp
WHERE LingoExpModelId = 981
ORDER BY partId, workerId