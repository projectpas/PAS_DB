/*************************************************************               
 ** File:  [usprpt_GetTrainingReport]      
 ** Author:  Bhargav Saliya
 ** Description: This stored procedure is used to GetTrainingReport DATA.    
 ** Purpose:             
 ** Date:   26-Feb-2025          
              
 ** RETURN VALUE:               
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date         Author			Change Description                
 ** --   --------     -------		--------------------------------              
    1    26-Feb-2025   Bhargav Saliya		Created    
         
************************************************************************/ 
CREATE   PROCEDURE [dbo].[usprpt_GetTrainingReport]  
@PageNumber int = 1,  
@PageSize int = NULL,  
@mastercompanyid int,  
@xmlFilter XML  
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
   DECLARE @level1 VARCHAR(MAX) = NULL,  
		   @level2 VARCHAR(MAX) = NULL,  
		   @level3 VARCHAR(MAX) = NULL,  
		   @level4 VARCHAR(MAX) = NULL,  
		   @Level5 VARCHAR(MAX) = NULL,  
		   @Level6 VARCHAR(MAX) = NULL,  
		   @Level7 VARCHAR(MAX) = NULL,  
		   @Level8 VARCHAR(MAX) = NULL,  
		   @Level9 VARCHAR(MAX) = NULL,  
		   @Level10 VARCHAR(MAX) = NULL ,
		   @ModuleID INT = 0
  SELECT @ModuleID = (SELECT ManagementStructureModuleId FROM ManagementStructureModule where ModuleName = 'EmployeeGeneralInfo');
  BEGIN TRY  
      
	SELECT   
		@level1=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level1'   
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level1 end,  
		@level2=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level2'   
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level2 end,  
		@level3=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level3'   
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level3 end,  
		@level4=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level4'   
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level4 end,  
		@level5=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level5'   
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level5 end,  
		@level6=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level6'   
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level6 end,  
		@level7=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level7'   
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level7 end,  
		@level8=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level8'   
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level8 end,  
		@level9=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level9'   
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level9 end,  
		@level10=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level10'   
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level10 end  
	FROM  
		@xmlFilter.nodes('/ArrayOfFilter/Filter')AS TEMPTABLE(filterby)  
  
	IF ISNULL(@PageSize,0)=0
	BEGIN 
		SELECT @PageSize=COUNT(*)
		FROM DBO.Employee E WITH (NOLOCK)
			INNER JOIN dbo.EmployeeManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = E.EmployeeId
			LEFT JOIN dbo.EntityStructureSetup ES WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID
			LEFT JOIN dbo.JobTitle J WITH (NOLOCK) ON E.JobTitleId = J.JobTitleId
			LEFT JOIN dbo.EmployeeTraining ET WITH (NOLOCK) ON E.EmployeeId = ET.EmployeeId
			LEFT JOIN dbo.EmployeeTrainingType ETP WITH (NOLOCK) ON ET.EmployeeTrainingTypeId = ETP.EmployeeTrainingTypeId
			LEFT JOIN dbo.FrequencyOfTraining FT WITH (NOLOCK) ON ET.FrequencyOfTrainingId = FT.FrequencyOfTrainingId
			LEFT JOIN dbo.AircraftType AFT WITH (NOLOCK) ON ET.AircraftManufacturerId = AFT.AircraftTypeId
		WHERE E.mastercompanyid = @mastercompanyid and E.IsActive =1 AND E.IsDeleted=0
		AND  (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
		AND  (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
		AND  (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
		AND  (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
		AND  (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
		AND  (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
		AND  (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
		AND  (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
		AND  (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
		AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))	
	END

  
   ;WITH rptCTE (TotalRecordsCount, EmployeeId,firstName, lastName, title, expertize, email, phone, trainingType,
				 provider, industryCode, frequency,duration,scheduleDate,completionDate,expirationDate,
				 daysToExpiration,inforce,aircraftType,model,issuingEntity,certNum,issueDate,
				 level1, level2, level3, level4, level5, level6, level7, level8,level9, level10) 
				 AS (
      SELECT COUNT(1) OVER () AS TotalRecordsCount,
	   E.EmployeeId,
       E.FirstName 'firstName',
       E.LastName 'lastName',
       J.Description 'title',
	   ISNULL((
			   SELECT STRING_AGG(EE.[Description],',') 
			   FROM STRING_SPLIT(E.EmployeeExpIds,',') AS ExpIds
					LEFT JOIN [DBO].EmployeeExpertise EE WITH(NOLOCK) ON EE.EmployeeExpertiseId = CAST(ExpIds.value AS INT)
			   WHERE ExpIds.value IS NOT NULL),'') 'expertize',
       E.Email 'email',
       E.MobilePhone 'phone',
	   ETP.TrainingType 'trainingType',
	   ET.Provider 'provider',
	   ET.IndustryCode 'industryCode',
	   FT.FrequencyName 'frequency',
	   ET.Duration 'duration',
	   FORMAT(ET.ScheduleDate,'MM-dd-yyyy') 'scheduleDate',
	   FORMAT(ET.CompletionDate,'MM-dd-yyyy') 'completionDate',
	   FORMAT(ET.ExpirationDate,'MM-dd-yyyy') 'expirationDate',
	   DATEDIFF(DAY, ET.ScheduleDate, ET.ExpirationDate) 'daysToExpiration',
	   CASE WHEN ISNULL(EC.IsCertificationInForce,0) = 1 THEN 'YES' ELSE 'NO' end AS inforce,
	   AFT.Description 'aircraftType',
	   '' model,
	   EC.CertifyingInstitution 'issuingEntity',
	   EC.CertificationNumber 'certNum',
	   ET.CreatedDate 'issueDate',
        UPPER(MSD.Level1Name) AS level1,  
		UPPER(MSD.Level2Name) AS level2, 
		UPPER(MSD.Level3Name) AS level3, 
		UPPER(MSD.Level4Name) AS level4, 
		UPPER(MSD.Level5Name) AS level5, 
		UPPER(MSD.Level6Name) AS level6, 
		UPPER(MSD.Level7Name) AS level7, 
		UPPER(MSD.Level8Name) AS level8, 
		UPPER(MSD.Level9Name) AS level9, 
		UPPER(MSD.Level10Name) AS level10  
      FROM DBO.Employee E WITH (NOLOCK)
	    INNER JOIN dbo.EmployeeManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = 47 AND MSD.ReferenceID = E.EmployeeId
		LEFT JOIN dbo.EntityStructureSetup ES WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID
		LEFT JOIN dbo.JobTitle J WITH (NOLOCK) ON E.JobTitleId = J.JobTitleId
		LEFT JOIN dbo.EmployeeTraining ET WITH (NOLOCK) ON E.EmployeeId = ET.EmployeeId
		LEFT JOIN dbo.EmployeeTrainingType ETP WITH (NOLOCK) ON ET.EmployeeTrainingTypeId = ETP.EmployeeTrainingTypeId
		LEFT JOIN dbo.FrequencyOfTraining FT WITH (NOLOCK) ON ET.FrequencyOfTrainingId = FT.FrequencyOfTrainingId
		LEFT JOIN dbo.AircraftType AFT WITH (NOLOCK) ON ET.AircraftManufacturerId = AFT.AircraftTypeId
		LEFT JOIN dbo.EmployeeCertification EC WITH (NOLOCK) ON E.EmployeeId = EC.EmployeeId


      WHERE E.mastercompanyid = @mastercompanyid and E.IsActive =1 AND E.IsDeleted=0
			AND  (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
			AND  (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
			AND  (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
			AND  (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
			AND  (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
			AND  (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
			AND  (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
			AND  (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
			AND  (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
			AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
			)
			,FinalCTE(TotalRecordsCount,EmployeeId, firstName, lastName, title, expertize, email, phone, trainingType,
				 provider, industryCode, frequency,duration,scheduleDate,completionDate,expirationDate,
				 daysToExpiration,inforce,aircraftType,model,issuingEntity,certNum,issueDate,
				 level1, level2, level3, level4, level5, level6, level7, level8,level9, level10) 

			  AS (SELECT DISTINCT TotalRecordsCount,EmployeeId, firstName, lastName, title, expertize, email, phone, trainingType,
				 provider, industryCode, frequency,duration,scheduleDate,completionDate,expirationDate,
				 daysToExpiration,inforce,aircraftType,model,issuingEntity,certNum,issueDate,
				 level1, level2, level3, level4, level5, level6, level7, level8,level9, level10 FROM rptCTE)
			
		    SELECT COUNT(2) OVER () AS TotalRecordsCount,EmployeeId, firstName, lastName, title, expertize, email, phone, trainingType,
				 provider, industryCode, frequency,duration,scheduleDate,completionDate,expirationDate,
				 daysToExpiration,inforce,aircraftType,model,issuingEntity,certNum,issueDate,
				 level1, level2, level3, level4, level5, level6, level7, level8,level9, level10
		    FROM FinalCTE FC

			ORDER BY EmployeeId DESC
		OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY; 
  END TRY  
  
  BEGIN CATCH  
   
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = '[usprpt_GetTrainingReport]',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100)) +    
            '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) +    
            '@Parameter3 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) +    
            '@Parameter4 = ''' + CAST(ISNULL(@xmlFilter, '') AS varchar(max)),  
            @ApplicationName varchar(100) = 'PAS'   
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR (  
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'  
    , 16, 1, @ErrorLogID)  
  
    RETURN (1);  
  END CATCH   
END