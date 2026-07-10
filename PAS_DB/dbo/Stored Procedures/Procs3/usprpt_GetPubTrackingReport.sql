
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.usprpt_GetPubTrackingReport   (source: PAS_DB/dbo/Stored Procedures/Procs3/usprpt_GetPubTrackingReport.sql)
-- ---------------------------------------------------------------------------------------------------
/*************************************************************             
 ** File:   [usprpt_GetPubTrackingReport]             
 ** Author:   Mahesh Sorathiya    
 ** Description: Get Data for Publication Tracking (CMM) Report  
 ** Purpose:           
 ** Date:   06-May-2022         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    06-May-2022    Mahesh Sorathiya   Created  
	2    01-SEPT-2023   Ekta Chandegra	   Convert text into uppercase
	3	 04-12-2024     Shrey Chandegara   Modified due to add some new column and add filter
	4    17-Jun-2026    Sahdev Saliya      Added PublicationType and PublicationTypeGloble [PN-15971]
	5    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

exec usprpt_GetPubTrackingReport @PageNumber=1,@PageSize=20,@SortColumn=NULL,@SortOrder=-1,@GlobalFilter=N'',@strFilter=N'1,5,6,52,84!2,7,8,9!3,11,10!4,13,12!!!!!!',@PublicationRecordId=0,
@PublicationId=NULL,@PartNumber=NULL,@PartDescription=NULL,@PublicationDescription=NULL,@VerifiedStatus=N'0',@DayToExpiry=NULL,@RedIndicator=0,@GreenIndicator=0,@YellowIndicator=0,@ExpirationStatus=N'0',
@Verified=NULL,@DaysToExp=NULL,@RevNumber=NULL,@VerifiedBy=NULL,@Manufacturer=NULL,@Source=NULL,@Location=NULL,@EntryDate=NULL,@FromEntryDate='2024-01-01 00:00:00',@ToEntryDate='2024-12-31 00:00:00',
@NextRevDate=NULL,@RevDate=NULL,@ExpirationDate=NULL,@VerifiedDate=NULL,@level1Str=NULL,@level2Str=NULL,@level3Str=NULL,@level4Str=NULL,@level5Str=NULL,@level6Str=NULL,@level7Str=NULL,@level8Str=NULL,@level9Str=NULL,@level10Str=NULL,@MasterCompanyId=1

**************************************************************/  
CREATE     PROCEDURE [dbo].[usprpt_GetPubTrackingReport] 
@PageNumber INT = NULL,
@PageSize INT = NULL,
@SortColumn VARCHAR(50)=NULL,
@SortOrder INT = NULL,
@GlobalFilter varchar(50) = NULL,
@PublicationRecordId BIGINT = NULL,
@strFilter VARCHAR(MAX) = NULL,
@PublicationId VARCHAR(150) =NULL,
@PartNumber NVARCHAR(100),
@PartDescription NVARCHAR(MAX),
@PublicationDescription NVARCHAR(MAX),
@VerifiedStatus NVARCHAR(100),
@DayToExpiry VARCHAR(200),
@RedIndicator INT,
@GreenIndicator INT,
@YellowIndicator INT,
@ExpirationStatus NVARCHAR(100),
@Verified NVARCHAR(100),
@DaysToExp  VARCHAR(50) = NULL,
@RevNumber NVARCHAR(100),
@VerifiedBy NVARCHAR(100),
@Manufacturer NVARCHAR(MAX),
@Source NVARCHAR(100),
@Location NVARCHAR(100),
@EntryDate DATETIME = NULL,
@FromEntryDate DATETIME = NULL,
@ToEntryDate DATETIME = NULL,
@NextRevDate DATETIME = NULL,
@RevDate DATETIME = NULL,
@ExpirationDate DATETIME = NULL,
@VerifiedDate DATETIME = NULL,
@level1Str VARCHAR(MAX) = NULL,
@level2Str VARCHAR(MAX) = NULL,
@level3Str VARCHAR(MAX) = NULL,
@level4Str VARCHAR(MAX) = NULL,
@level5Str VARCHAR(MAX) = NULL,
@level6Str VARCHAR(MAX) = NULL,
@level7Str VARCHAR(MAX) = NULL,
@level8Str VARCHAR(MAX) = NULL,
@level9Str VARCHAR(MAX) = NULL,
@level10Str VARCHAR(MAX) = NULL,
@MasterCompanyId INT,
@PublicationType VARCHAR(256) = NULL,
@PublicationTypeGloble VARCHAR(100) = NULL
 
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
  
  
  BEGIN TRY  

		DECLARE @Total INT;
		DECLARE @RecordFrom INT;

		SET @RecordFrom = (@PageNumber - 1) * @PageSize;
		  IF @SortColumn IS NULL
		  BEGIN
	  		SET @SortColumn = UPPER('EXPIRATIONDATE')		
		  END 
		  ELSE
		  BEGIN 
	  		SET @SortColumn = UPPER(@SortColumn)		
		  END	
    
	   IF OBJECT_ID(N'tempdb..#TEMPMSFilter') IS NOT NULL    
		BEGIN    
			DROP TABLE #TEMPMSFilter
		END

		CREATE TABLE #TEMPMSFilter([ID] BIGINT  IDENTITY(1,1),[LevelIds] VARCHAR(MAX)); 

		INSERT INTO #TEMPMSFilter(LevelIds)	SELECT Item FROM DBO.SPLITSTRING(@strFilter,'!');

		DECLARE @DefaultDate AS DATE = CAST(GETDATE() AS DATE);
		DECLARE @ExpireStatus VARCHAR(50) = 'EXPIRED';
		DECLARE @NonExpireStatus VARCHAR(50) = 'NONEXPIRED';
		DECLARE @AllStatus VARCHAR(50) = 'ALL';
		DECLARE @NotSelectStatus VARCHAR(50) = '0';
		DECLARE @VerifyStatus VARCHAR(50) = 'VERIFIED';
		DECLARE @NonVerifyStatus VARCHAR(50) = 'NONVERIFIED';
		DECLARE @VerStatus VARCHAR(100) = NULL;
		SET @VerStatus = CASE WHEN UPPER(@VerifiedStatus) = @VerifyStatus THEN '1' 
							  WHEN UPPER(@VerifiedStatus) = @NonVerifyStatus THEN '0'
							  ELSE '1,0' END ;

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
		@Level10 VARCHAR(MAX) = NULL 

		SELECT @level1 = LevelIds FROM #TEMPMSFilter WHERE ID = 1 
		SELECT @level2 = LevelIds FROM #TEMPMSFilter WHERE ID = 2 
		SELECT @level3 = LevelIds FROM #TEMPMSFilter WHERE ID = 3 
		SELECT @level4 = LevelIds FROM #TEMPMSFilter WHERE ID = 4 
		SELECT @level5 = LevelIds FROM #TEMPMSFilter WHERE ID = 5 
		SELECT @level6 = LevelIds FROM #TEMPMSFilter WHERE ID = 6 
		SELECT @level7 = LevelIds FROM #TEMPMSFilter WHERE ID = 7 
		SELECT @level8 = LevelIds FROM #TEMPMSFilter WHERE ID = 8 
		SELECT @level9 = LevelIds FROM #TEMPMSFilter WHERE ID = 9 
		SELECT @level10 = LevelIds FROM #TEMPMSFilter WHERE ID = 10 

	 
		DECLARE @ModuleID INT = 60; -- MS Module ID

		BEGIN
		 IF OBJECT_ID(N'tempdb..#tmpPublication') IS NOT NULL      
		 BEGIN      
		  DROP TABLE #tmpPublication      
		END 

		IF OBJECT_ID(N'tempdb..#finalResult') IS NOT NULL      
		 BEGIN      
		  DROP TABLE #finalResult    
		END 

		CREATE TABLE #tmpPublication     
		 (      
		  ID BIGINT NOT NULL IDENTITY,
		  PublicationRecordId BIGINT NULL,
		  PublicationId VARCHAR(150) NULL,
		  PartNumber VARCHAR(100) NULL,
		  PartDescription VARCHAR(MAX) NULL,
		  PublicationDescription VARCHAR(MAX) NULL,
		  --VerifiedStatus VARCHAR(100) NULL,
		  --ExpirationStatus VARCHAR(100) NULL,
		  Verified VARCHAR(100) NULL,
		  RedIndicator INT,
		  YellowIndicator INT,
		  GreenIndicator INT,
		  DaysToExpiration VARCHAR(50) NULL,
		  DaysToExp VARCHAR(50) NULL,
		  RevNumber VARCHAR(100) NULL,
		  VerifiedBy VARCHAR(100) NULL,
		  Manufacturer VARCHAR(MAX) NULL,
		  Source VARCHAR(200) NULL,
		  Location VARCHAR(200) NULL,
		  EntryDate DATETIME NULL,
		  NextRevDate DATETIME NULL,
		  RevDate DATETIME NULL,
		  ExpirationDate DATETIME NULL,
		  VerifiedDate DATETIME NULL,
		  level1 VARCHAR(MAX)  NULL,
		  level2 VARCHAR(MAX)  NULL,
		  level3 VARCHAR(MAX)  NULL,
		  level4 VARCHAR(MAX)  NULL,
		  level5 VARCHAR(MAX)  NULL,
		  level6 VARCHAR(MAX)  NULL,
		  level7 VARCHAR(MAX)  NULL,
		  level8 VARCHAR(MAX)  NULL,
		  level9 VARCHAR(MAX)  NULL,
		  level10 VARCHAR(MAX) NULL,
		  PublicationType VARCHAR(256) NULL
		 )    

		 INSERT INTO #tmpPublication (PublicationRecordId,PublicationId, PartNumber, PartDescription, PublicationDescription, Verified, RedIndicator,YellowIndicator,GreenIndicator, DaysToExpiration,DaysToExp, RevNumber,
										VerifiedBy, Manufacturer, Source,Location, EntryDate, NextRevDate, RevDate, ExpirationDate, VerifiedDate, level1, level2, level3,
										level4, level5, level6, level7, level8, level9, level10, PublicationType) 

		 SELECT 
			 PUB.PublicationRecordId,
			 PUB.PublicationId,
			 IM.partnumber,
			 IM.PartDescription ,
			 PUB.Description ,
			 CASE WHEN PUB.VerifiedDate IS NOT NULL AND CAST(PUB.VerifiedDate AS DATE) <= CAST(GETUTCDATE() AS DATE) THEN 'YES' ELSE 'NO' END 'Verified',
			 STS.RedIndicator,
			 STS.YellowIndicator,
			 STS.GreenIndicator,
			 --CASE WHEN DATEDIFF(day, @DefaultDate, ISNULL(CAST(PUB.ExpirationDate AS DATE),'')) > 30 THEN 'GREEN' 
				--  WHEN 30 > DATEDIFF(day, @DefaultDate, ISNULL(CAST(PUB.ExpirationDate AS DATE),'')) AND  DATEDIFF(day, @DefaultDate, ISNULL(CAST(PUB.ExpirationDate AS DATE),'')) > 10 THEN 'YELLOW'
				--  WHEN ISNULL(PUB.ExpirationDate,'') = ''  THEN 'WHITE'
				--  ELSE 'RED' END,
			 CASE WHEN ISNULL(PUB.ExpirationDate, '') != '' THEN 
				CASE WHEN DATEDIFF(day, @DefaultDate, CAST(PUB.ExpirationDate AS DATE)) < 0 THEN '(' + CAST(ABS(DATEDIFF(day, @DefaultDate, CAST(PUB.ExpirationDate AS DATE))) AS VARCHAR) + ')'
				ELSE CAST(DATEDIFF(day, @DefaultDate, CAST(PUB.ExpirationDate AS DATE)) AS VARCHAR) END ELSE 'NA' END,
				CASE WHEN ISNULL(PUB.ExpirationDate, '') != '' THEN CAST((DATEDIFF(day, @DefaultDate, CAST(PUB.ExpirationDate AS DATE))) AS VARCHAR) ELSE 'NA' END,
			 PUB.revisionnum,
			 (E.firstname + ' ' + E.lastname) AS 'VerifiedBy',
			 MNFR.name AS Manufacturer,
			 WFPUB.Source AS 'source',
			 LC.Name AS 'location',
			 PUB.EntryDate,
			 PUB.NextReviewDate,
			 PUB.revisionDate,
			 PUB.ExpirationDate,
			 PUB.VerifiedDate,
			 UPPER(MSD.Level1Name) AS level1,  
			 UPPER(MSD.Level2Name) AS level2, 
			 UPPER(MSD.Level3Name) AS level3, 
			 UPPER(MSD.Level4Name) AS level4, 
			 UPPER(MSD.Level5Name) AS level5, 
			 UPPER(MSD.Level6Name) AS level6, 
			 UPPER(MSD.Level7Name) AS level7, 
			 UPPER(MSD.Level8Name) AS level8, 
			 UPPER(MSD.Level9Name) AS level9, 
			 UPPER(MSD.Level10Name) AS level10,
			 PT.Name AS PublicationType

		 FROM [dbo].[Publication] PUB WITH (NOLOCK)
			 INNER JOIN DBO.PublicationItemMasterMapping PIMM WITH (NOLOCK) ON PUB.PublicationRecordId = PIMM.PublicationRecordId AND PIMM.IsActive = 1 AND PIMM.IsDeleted = 0
			 INNER JOIN DBO.Itemmaster IM WITH (NOLOCK) ON PIMM.ItemMasterId = IM.ItemMasterId
			 INNER JOIN dbo.PublicationManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.PublicationRecordId = PUB.PublicationRecordId
			 LEFT JOIN DBO.Manufacturer MNFR WITH (NOLOCK) ON IM.ManufacturerId = MNFR.ManufacturerId
			 LEFT JOIN DBO.WorkflowPublications WFPUB WITH (NOLOCK) ON PUB.PublicationRecordId = WFPUB.PublicationId
			 LEFT JOIN DBO.Location LC WITH (NOLOCK) ON PUB.LocationId = LC.LocationId
			 LEFT JOIN DBO.Employee E WITH (NOLOCK) ON PUB.VerifiedBy = E.EmployeeId
			 LEFT JOIN PublicationSettings STS WITH (NOLOCK) ON STS.MasterCompanyId =@MasterCompanyId
			 LEFT JOIN PublicationType PT WITH (NOLOCK) ON PUB.PublicationTypeId = PT.PublicationTypeId
		 WHERE PUB.entrydate BETWEEN (@FromEntryDate) AND (@ToEntryDate) AND PUB.MasterCompanyId = @MasterCompanyId AND PUB.IsActive = 1 AND PUB.IsDeleted = 0
			   AND PUB.VerifiedStatus IN (SELECT * FROM DBO.SplitString(@VerStatus,','))
			   AND ( @ExpirationStatus = @ExpireStatus AND ISNULL(CAST(PUB.ExpirationDate AS DATE),'') < @DefaultDate OR
					 @ExpirationStatus = @NonExpireStatus AND ISNULL(CAST(PUB.ExpirationDate AS DATE),'') > @DefaultDate OR
					 @ExpirationStatus = @AllStatus OR @ExpirationStatus = @NotSelectStatus)
				AND(ISNULL(@level1Str,'') ='' OR [Level1Name] LIKE '%' + @level1Str + '%') AND
				(ISNULL(@level2Str,'') ='' OR [level2Name] LIKE '%' + @level2Str + '%') AND
				(ISNULL(@level3Str,'') ='' OR [level3Name] LIKE '%' + @level3Str + '%') AND
				(ISNULL(@level4Str,'') ='' OR [level4Name] LIKE '%' + @level4Str + '%') AND
				(ISNULL(@level5Str,'') ='' OR [level5Name] LIKE '%' + @level5Str + '%') AND
				(ISNULL(@level6Str,'') ='' OR [level6Name] LIKE '%' + @level6Str + '%') AND
				(ISNULL(@level7Str,'') ='' OR [level7Name] LIKE '%' + @level7Str + '%') AND
				(ISNULL(@level8Str,'') ='' OR [level8Name] LIKE '%' + @level8Str + '%') AND
				(ISNULL(@level9Str,'') ='' OR [level9Name] LIKE '%' + @level9Str + '%') AND
				(ISNULL(@level10Str,'') ='' OR [level10Name] LIKE '%' + @level10Str + '%') AND
				(ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
				(ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
				(ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
				(ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
				(ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
				(ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
				(ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
				(ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
				(ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
				(ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				
		   AND ISNULL(IM.IsNonStock,0) = 0
				 SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
		  SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END

		 select * into #finalResult
		 FROM #tmpPublication
		 WHERE (
			 (ISNULL(@PublicationId,'') ='' OR [PublicationId]  LIKE '%' +@PublicationId +'%') and
			 (ISNULL(@PartNumber,'') ='' OR [PartNumber] LIKE '%' + @PartNumber+'%') AND
			 (ISNULL(@PartDescription,'') ='' OR [PartDescription] LIKE '%' + @PartDescription+'%') AND
			 (ISNULL(@PublicationDescription, '') = '' OR [PublicationDescription] LIKE '%' + @PublicationDescription + '%') AND
			 (ISNULL(@Verified, '') = '' OR [Verified] LIKE '%' + @Verified + '%') AND
			 (ISNULL(@DaysToExp, '') = '' OR [DaysToExpiration] LIKE '%' + @DaysToExp+ '%') AND 
			 (ISNULL(@RevNumber, '') = '' OR [RevNumber] LIKE '%' + @RevNumber + '%') AND 
			 (ISNULL(@VerifiedBy, '') = '' OR [VerifiedBy] LIKE '%' + @VerifiedBy + '%') AND 
			 (ISNULL(@Manufacturer, '') = '' OR [Manufacturer] LIKE '%' + @Manufacturer + '%') AND
			 (ISNULL(@Source, '') = '' OR [Source] LIKE '%' + @Source + '%') AND
			 (ISNULL(@Location, '') = '' OR [Location] LIKE '%' + @Location + '%') AND
			 (ISNULL(@EntryDate, '') = '' OR CAST([EntryDate] AS DATE) =  CAST(@EntryDate AS DATE) ) AND 
			 (ISNULL(@NextRevDate, '') = '' OR CAST([NextRevDate] AS DATE) =  CAST(@NextRevDate AS DATE) ) AND 
			 (ISNULL(@RevDate, '') = '' OR CAST([RevDate] AS DATE) =  CAST(@RevDate AS DATE)) AND 
			 (ISNULL(@ExpirationDate, '') = '' OR CAST([ExpirationDate] AS DATE) = CAST(@ExpirationDate AS DATE)) AND 
			 (ISNULL(@VerifiedDate, '') = '' OR CAST([VerifiedDate] AS DATE) =  CAST(@VerifiedDate AS DATE)) AND
			 (ISNULL(@PublicationType, '') = '' OR EXISTS (SELECT 1 FROM STRING_SPLIT(@PublicationType, ',') pt WHERE UPPER([PublicationType]) LIKE '%' + UPPER(LTRIM(RTRIM(pt.value))) + '%')) AND
			 ( ISNULL(@PublicationTypeGloble, '') = '' OR EXISTS (SELECT 1 FROM STRING_SPLIT(@PublicationTypeGloble, ',') pt WHERE UPPER([PublicationType]) = UPPER(LTRIM(RTRIM(pt.value)))))
			 )

		 SET @Total = (SELECT TOP 1 COUNT(1) OVER () AS TotalRecordsCount FROM #finalResult);
		 select @Total as NumberOfItems, * from #finalResult
		 ORDER BY
			CASE WHEN (@SortOrder=1  AND @SortColumn='PublicationId') THEN [PublicationId] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PublicationId') THEN [PublicationId] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PARTNUMBER') THEN [PartNumber] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTNUMBER') THEN [PartNumber] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PartDescription') THEN [PartDescription] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PartDescription') THEN [PartDescription] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PublicationDescription') THEN [PublicationDescription] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PublicationDescription') THEN [PublicationDescription] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'Verified') THEN [Verified] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'Verified') THEN [Verified] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'DaysToExpiration') THEN [DaysToExpiration] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'DaysToExpiration') THEN [DaysToExpiration] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'RevNumber') THEN [RevNumber] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'RevNumber') THEN [RevNumber] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'VerifiedBy') THEN [VerifiedBy] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'VerifiedBy') THEN [VerifiedBy] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'Manufacturer') THEN [Manufacturer] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'Manufacturer') THEN [Manufacturer] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'Source') THEN [Source] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'Source') THEN [Source] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'Location') THEN [Location] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'Location') THEN [Location] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'EntryDate') THEN [EntryDate] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'EntryDate') THEN [EntryDate] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'NextRevDate') THEN [NextRevDate] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'NextRevDate') THEN [NextRevDate] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'RevDate') THEN [RevDate] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'RevDate') THEN [RevDate] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'ExpirationDate') THEN [ExpirationDate] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ExpirationDate') THEN [ExpirationDate] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'VerifiedDate') THEN [VerifiedDate] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'VerifiedDate') THEN [VerifiedDate] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LEVEL1') THEN [Level1] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LEVEL1') THEN [Level1] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LEVEL2') THEN [Level2] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LEVEL2') THEN [Level2] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LEVEL3') THEN [Level3] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LEVEL3') THEN [Level3] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LEVEL4') THEN [Level4] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LEVEL4') THEN [Level4] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LEVEL5') THEN [Level5] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LEVEL5') THEN [Level5] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LEVEL6') THEN [Level6] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LEVEL6') THEN [Level6] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LEVEL7') THEN [Level7] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LEVEL7') THEN [Level7] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LEVEL8') THEN [Level8] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LEVEL8') THEN [Level8] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LEVEL9') THEN [Level9] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LEVEL9') THEN [Level9] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LEVEL10') THEN [Level10] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LEVEL10') THEN [Level10] END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'PublicationType') THEN [PublicationType] END ASC,
            CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PublicationType') THEN [PublicationType] END DESC
			OFFSET @RecordFrom ROWS 
   			FETCH NEXT @PageSize ROWS ONLY

	 END
   
  END TRY  
  
  BEGIN CATCH  
    SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    DECLARE @ErrorLogID int,  
	
            @DatabaseName varchar(100) = DB_NAME(), 
			
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = '[usprpt_GetPubTrackingReport]',  
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