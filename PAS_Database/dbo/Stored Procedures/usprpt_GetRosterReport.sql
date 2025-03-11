/*************************************************************             
 ** File:   [usprpt_GetRosterReport]             
 ** Author:   Sahdev Saliya    
 ** Description: Get Data for Employee Roster Report  
 ** Purpose:           
 ** Date:   11-03-2025         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    11-03-2025    Sahdev Saliya       Created  

**************************************************************/  

CREATE     PROCEDURE [dbo].[usprpt_GetRosterReport]
@PageNumber INT = 1,
@PageSize INT = NULL,
@mastercompanyid INT,
@xmlFilter XML

AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
  DECLARE 
	@level1 VARCHAR(MAX) = NULL,
	@level2 VARCHAR(MAX) = NULL,
	@level3 VARCHAR(MAX) = NULL,
	@level4 VARCHAR(MAX) = NULL,
	@Level5 VARCHAR(MAX) = NULL,
	@Level6 VARCHAR(MAX) = NULL,
	@Level7 VARCHAR(MAX) = NULL,
	@Level8 VARCHAR(MAX) = NULL,
	@Level9 VARCHAR(MAX) = NULL,
	@Level10 VARCHAR(MAX) = NULL,
	@IsDownload BIT = NULL

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
		   FROM DBO.Employee EMP WITH (NOLOCK)  
           INNER JOIN dbo.EmployeeManagementStructureDetails EMS WITH (NOLOCK) ON EMS.ModuleID = 47 AND EMS.ReferenceID = EMP.EmployeeId
	       LEFT JOIN dbo.EntityStructureSetup ES WITH (NOLOCK) ON ES.EntityStructureId = EMS.EntityMSID
	       LEFT JOIN  dbo.AspNetUsers ASP WITH (NOLOCK) ON EMP.EmployeeId = ASP.EmployeeId
	       LEFT JOIN  dbo.JobTitle jot WITH (NOLOCK) ON EMP.JobTitleId = jot.JobTitleId	
		    WHERE EMP.mastercompanyid = @mastercompanyid 
	        AND EMP.IsActive = 1 AND EMP.IsDeleted = 0
		    AND  (ISNULL(@Level1,'') ='' OR EMS.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
			AND  (ISNULL(@Level2,'') ='' OR EMS.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
			AND  (ISNULL(@Level3,'') ='' OR EMS.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
			AND  (ISNULL(@Level4,'') ='' OR EMS.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
			AND  (ISNULL(@Level5,'') ='' OR EMS.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
			AND  (ISNULL(@Level6,'') ='' OR EMS.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
			AND  (ISNULL(@Level7,'') ='' OR EMS.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
			AND  (ISNULL(@Level8,'') ='' OR EMS.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
			AND  (ISNULL(@Level9,'') ='' OR EMS.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
			AND  (ISNULL(@Level10,'') =''  OR EMS.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
		END

        ;WITH rptCTE (TotalRecordsCount, firstName, lastName, username, title, expertize, managmentrole,
				       certifyingstaff, supervisorname, email,phone,startdate,enddate,
				       level1, level2, level3, level4, level5, level6, level7, level8,level9, level10) 
				 AS (
      SELECT COUNT(1) OVER () AS TotalRecordsCount,
	    UPPER(EMP.FirstName) 'firstname',  
        UPPER(EMP.LastName) 'lastname',  
		UPPER(ASP.UserName) 'username', 
		UPPER(jot.[Description]) 'title',  
        ISNULL((SELECT STRING_AGG(EE.[Description],',') 
			  FROM STRING_SPLIT(EMP.EmployeeExpIds,',') AS ExpIds
					LEFT JOIN [DBO].EmployeeExpertise EE WITH(NOLOCK) ON EE.EmployeeExpertiseId = CAST(ExpIds.value AS INT)
			   WHERE ExpIds.value IS NOT NULL),'') 'expertize',  
		(SELECT STRING_AGG(UR.Name, ', ') 
		     FROM dbo.EmployeeUserRole EUR WITH (NOLOCK)  
		            LEFT JOIN dbo.UserRole UR WITH (NOLOCK) ON EUR.RoleId = UR.Id  
		     WHERE EUR.EmployeeId = EMP.EmployeeId) AS 'managmentrole',
		CASE WHEN EMP.EmployeeCertifyingStaff = 1 THEN 'Yes' ELSE 'No' END AS certifyingstaff,
        UPPER(EMP.FirstName +' '+ EMP.LastName) 'supervisorname',  
		UPPER(EMP.Email) 'email', 
		UPPER(EMP.MobilePhone) 'phone',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(EMP.StartDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), EMP.StartDate, 107) END 'startdate', 
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(EMP.UpdatedDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), EMP.UpdatedDate, 107) END 'enddate', 
		UPPER(EMS.Level1Name) AS level1,  
		UPPER(EMS.Level2Name) AS level2, 
		UPPER(EMS.Level3Name) AS level3, 
		UPPER(EMS.Level4Name) AS level4, 
		UPPER(EMS.Level5Name) AS level5, 
		UPPER(EMS.Level6Name) AS level6, 
		UPPER(EMS.Level7Name) AS level7, 
		UPPER(EMS.Level8Name) AS level8, 
		UPPER(EMS.Level9Name) AS level9, 
		UPPER(EMS.Level10Name) AS level10   
      FROM DBO.Employee EMP WITH (NOLOCK)  
	  INNER JOIN dbo.EmployeeManagementStructureDetails EMS WITH (NOLOCK) ON EMS.ModuleID = 47 AND EMS.ReferenceID = EMP.EmployeeId
	  LEFT JOIN dbo.EntityStructureSetup ES WITH (NOLOCK) ON ES.EntityStructureId = EMS.EntityMSID
	  LEFT JOIN  dbo.AspNetUsers ASP WITH (NOLOCK) ON EMP.EmployeeId = ASP.EmployeeId
	  LEFT JOIN  dbo.JobTitle jot WITH (NOLOCK) ON EMP.JobTitleId = jot.JobTitleId
	  WHERE EMP.mastercompanyid = @mastercompanyid 
	  AND EMP.IsActive = 1 AND EMP.IsDeleted = 0
			AND  (ISNULL(@Level1,'') ='' OR EMS.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
			AND  (ISNULL(@Level2,'') ='' OR EMS.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
			AND  (ISNULL(@Level3,'') ='' OR EMS.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
			AND  (ISNULL(@Level4,'') ='' OR EMS.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
			AND  (ISNULL(@Level5,'') ='' OR EMS.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
			AND  (ISNULL(@Level6,'') ='' OR EMS.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
			AND  (ISNULL(@Level7,'') ='' OR EMS.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
			AND  (ISNULL(@Level8,'') ='' OR EMS.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
			AND  (ISNULL(@Level9,'') ='' OR EMS.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
			AND  (ISNULL(@Level10,'') =''  OR EMS.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
			)
			,FinalCTE(TotalRecordsCount, firstname, lastname, username, title, expertize, managmentrole, certifyingstaff,
				 supervisorname, email, phone, startdate, enddate, level1, level2, level3, level4, level5, level6, level7, level8,
			  level9, level10) 
			  AS (SELECT DISTINCT TotalRecordsCount, firstname, lastname, username, title, expertize, managmentrole, certifyingstaff,
				 supervisorname, email, phone, startdate, enddate, level1, level2, level3, level4, level5, level6, level7, level8,
			  level9, level10 FROM rptCTE)
			
		    SELECT COUNT(2) OVER () AS TotalRecordsCount, firstname, lastname, username, title, expertize, managmentrole, certifyingstaff,
				 supervisorname, email, phone, startdate, enddate, level1, level2, level3, level4, level5, level6, level7, level8,
			  level9, level10
		    FROM FinalCTE FC
	   ORDER BY firstname
	   OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;
   
  END TRY  

  BEGIN CATCH  
  
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(), 
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = '[usprpt_GetRosterReport]',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100)) +  
            '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) +  
            '@Parameter3 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)),
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