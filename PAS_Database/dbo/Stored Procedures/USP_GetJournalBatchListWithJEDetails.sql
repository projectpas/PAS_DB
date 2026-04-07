/*************************************************************                 
 ** File:   [USP_GetJournalBatchListWithJEDetails]                
 ** Author:   Bhargav Saliya     
 ** Description: Get JournalBatchListWithJEDetails         
 ** Purpose:               
 ** Date:    06/04/2026           
                
        
 **************************************************************                 
  ** Change History                 
 **************************************************************                 
 ** PR   Date         Author  Change	Description                  
 ** --   --------     -------  ------	--------------------------                
    1    06/04/2026   Bhargav Saliya	Created      

 -- exec USP_GetJournalBatchDataList 92,1          
**************************************************************/       
            
CREATE   PROCEDURE [dbo].[USP_GetJournalBatchListWithJEDetails]      
@PageSize int,        
@PageNumber int,        
@SortColumn varchar(50)= null,        
@SortOrder int= null,       
@GlobalFilter varchar(50)=null,      
@StatusID int= null,        
@BatchName varchar(50),      
@EntryDate datetime=null,      
@PostDate datetime=null,      
@AccountingPeriod varchar(50)= null,      
@StatusName varchar(50)=null,      
@JournalTypeName varchar(50)=null,      
@TotalDebit varchar(50)= null,      
@TotalCredit varchar(50)=null,      
@TotalBalance varchar(50)= null,      
@MasterCompanyId int= null,      
@EmployeeId bigint,      
@IsDeleted bit= null,      
@CreatedBy varchar(50),  
@UpdatedBy varchar(50),
@PostedBy varchar(50),
@JeNumber varchar(100) = NULL,
@IsError varchar(50) = null,
@JournalTypeNumber varchar(100) = NULL
AS      
BEGIN      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
 SET NOCOUNT ON;      
 BEGIN TRY      
      
        
	DECLARE @RecordFrom INT;       
	Declare @IsActive BIT = 1        
	Declare @Count INT;  
	DECLARE @HeadersIdValue VARCHAR(MAX);

	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
	SELECT 
		@CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description],LTZ.[Description]) 
	FROM dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
	WHERE E.EmployeeId = @EmployeeId;

	SET @RecordFrom = (@PageNumber - 1) * @PageSize;      
	   
	IF(@GlobalFilter is null)      
	BEGIN      
		SET @GlobalFilter='';      
	END      
	   
	IF @SortColumn is null        
	BEGIN        
		SET @SortColumn = 'JournalBatchHeaderId'        
	End         
	ELSE        
	BEGIN         
		SET @SortColumn = UPPER(@SortColumn)        
	END      
	
	IF(@JeNumber IS NULL OR @JeNumber = '')
	BEGIN
	;WITH CBD_Grouped AS
	(
		SELECT 
			JournalBatchHeaderId,
			SUM(DebitAmount) AS DebitAmount,
			SUM(CreditAmount) AS CreditAmount,
			JournalTypeNumber
		FROM dbo.CommonBatchDetails WITH (NOLOCK)
		GROUP BY JournalBatchHeaderId,JournalTypeNumber
	),
	 Result AS(
		   SELECT JBH.[JournalBatchHeaderId]      
				  ,JBH.[BatchName]      
				  ,JBH.[CurrentNumber]    
				  ,(Cast(DBO.ConvertUTCtoLocal(JBH.[EntryDate],@CurrntEmpTimeZoneDesc)AS DATETIME)) as EntryDate
				  ,(Cast(DBO.ConvertUTCtoLocal(JBH.[PostDate],@CurrntEmpTimeZoneDesc)AS DATETIME)) as PostDate
				  ,JBH.[AccountingPeriod]      
				  ,JBH.[StatusId]      
				  ,JBH.[StatusName]      
				  ,JBH.[JournalTypeId]      
				  ,JBH.[JournalTypeName]      
				  ,CBD.[DebitAmount] AS TotalDebit    
				  ,CBD.[CreditAmount] as TotalCredit   
				  ,JBH.[TotalBalance]      
				  ,JBH.[MasterCompanyId]      
				  ,JBH.[CreatedBy]      
				  ,JBH.[UpdatedBy]      
				  ,(Cast(DBO.ConvertUTCtoLocal(JBH.[CreatedDate],@CurrntEmpTimeZoneDesc)AS DATETIME)) as CreatedDate
				  ,(Cast(DBO.ConvertUTCtoLocal(JBH.[UpdatedDate],@CurrntEmpTimeZoneDesc)AS DATETIME)) as UpdatedDate
				  ,JBH.[IsActive]      
				  ,JBH.[IsDeleted]  
				  ,JBH.[PostedBy]
				  ,JBH.[Module]      
				  ,CASE WHEN ISNULL(JBH.[TotalBalance],0) <> 0 THEN 'YES' ELSE 'NO' END AS IsError
				  ,CBD.[JournalTypeNumber]
			FROM [dbo].[BatchHeader] JBH WITH(NOLOCK)      
			INNER JOIN CBD_Grouped CBD ON JBH.JournalBatchHeaderId = CBD.JournalBatchHeaderId
			WHERE ((JBH.MasterCompanyId = @MasterCompanyId) AND (JBH.IsDeleted = @IsDeleted) AND (@StatusID=0 OR JBH.StatusId = @StatusID))
			), ResultCount AS(SELECT COUNT(JournalBatchHeaderId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			WHERE (        
				(@GlobalFilter <>'' AND (        
				(BatchName like '%' +@GlobalFilter+'%') OR        
				(EntryDate like '%' +@GlobalFilter+'%') OR        
				(PostDate like '%' +@GlobalFilter+'%') OR        
				(AccountingPeriod like '%' +@GlobalFilter+'%') OR        
				(StatusName like '%'+@GlobalFilter+'%') OR        
				(JournalTypeName like '%'+@GlobalFilter+'%') OR        
		        ((CAST(TotalDebit AS NVARCHAR(20))) LIKE '%' +@GlobalFilter+'%') OR       
		        ((CAST(TotalCredit AS NVARCHAR(20))) LIKE '%' +@GlobalFilter+'%') OR       
		        ((CAST(TotalBalance AS NVARCHAR(20))) LIKE '%' +@GlobalFilter+'%') OR       
				(CreatedBy like '%' +@GlobalFilter+'%')  OR  
				(UpdatedBy like '%' +@GlobalFilter+'%') OR
				(PostedBy like '%' +@GlobalFilter+'%') OR
				(JournalTypeNumber like '%' +@GlobalFilter+'%')
				))        
				OR           
				(@GlobalFilter='' AND (IsNull(@BatchName,'') ='' OR BatchName like '%' + @BatchName+'%') AND        
				(IsNull(@EntryDate,'') ='' OR (Cast(DBO.ConvertUTCtoLocal(EntryDate ,@CurrntEmpTimeZoneDesc) as Date))=Cast(@EntryDate as date)) AND        
				(IsNull(@PostDate,'') ='' OR (Cast(DBO.ConvertUTCtoLocal(PostDate,@CurrntEmpTimeZoneDesc) as Date))=Cast(@PostDate as date)) AND        
				(IsNull(@AccountingPeriod,'') ='' OR AccountingPeriod like '%' + @AccountingPeriod+'%') AND        
				(IsNull(@StatusName,'') ='' OR StatusName like '%' + @StatusName+'%') AND        
				(IsNull(@JournalTypeName,'') ='' OR JournalTypeName like '%' + @JournalTypeName+'%') AND      
				(IsNull(@TotalDebit,'') ='' OR CAST(TotalDebit AS varchar(20)) like '%' + @TotalDebit+'%' ) AND       
				(IsNull(@TotalCredit,'') ='' OR CAST(TotalCredit AS varchar(20)) like '%' + @TotalCredit+'%' ) AND        
				(IsNull(@TotalBalance,'') ='' OR CAST(TotalBalance AS varchar(20)) like '%' + @TotalBalance+'%') AND       
				(IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND  
				(IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') AND
				(IsNull(@PostedBy,'') ='' OR PostedBy like '%' + @PostedBy+'%') 
				AND (IsNull(@IsError,'') ='' OR IsError like '%' + @IsError+'%')
				AND (IsNull(@JournalTypeNumber,'') ='' OR JournalTypeNumber like '%' + @JournalTypeNumber+'%')
				))  
				SELECT @Count = COUNT(JournalBatchHeaderId) FROM #TempResult
				SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY 

				CASE WHEN (@SortOrder=1 and @SortColumn='JournalBatchHeaderId')  THEN JournalBatchHeaderId END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='BatchName')  THEN BatchName END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='EntryDate')  THEN EntryDate END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='PostDate')  THEN PostDate END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='AccountingPeriod')  THEN AccountingPeriod END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='StatusName')  THEN StatusName END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='JournalTypeName')  THEN JournalTypeName END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='TotalDebit')  THEN CAST(TotalDebit AS varchar(20)) END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='TotalCredit')  THEN CAST(TotalCredit AS varchar(20)) END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='TotalBalance')  THEN CAST(TotalBalance AS varchar(20)) END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='CreatedBy')  THEN CreatedBy END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='PostedBy')  THEN PostedBy END ASC, 
				CASE WHEN (@SortOrder=1 and @SortColumn='IsError')  THEN IsError END ASC, 
				CASE WHEN (@SortOrder=1 and @SortColumn='JournalTypeNumber')  THEN JournalTypeNumber END ASC, 
        
				CASE WHEN (@SortOrder=-1 and @SortColumn='JournalBatchHeaderId')  THEN JournalBatchHeaderId END Desc,       
				CASE WHEN (@SortOrder=-1 and @SortColumn='BatchName')  THEN BatchName END Desc,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='EntryDate')  THEN EntryDate END Desc,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='PostDate')  THEN PostDate END Desc,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='AccountingPeriod')  THEN AccountingPeriod END Desc,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='StatusName')  THEN StatusName END Desc,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='JournalTypeName')  THEN JournalTypeName END Desc,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='TotalDebit')  THEN CAST(TotalDebit AS varchar(20))  END Desc,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='TotalCredit')  THEN CAST(TotalCredit AS varchar(20)) END Desc,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='TotalBalance')  THEN CAST(TotalBalance AS varchar(20)) END Desc,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedBy')  THEN CreatedBy END Desc,     
				CASE WHEN (@SortOrder=-1 and @SortColumn='UpdatedBy')  THEN UpdatedBy END Desc,
				CASE WHEN (@SortOrder=-1 and @SortColumn='PostedBy')  THEN PostedBy END Desc   
				,CASE WHEN (@SortOrder=-1 and @SortColumn='IsError')  THEN IsError END Desc
				,CASE WHEN (@SortOrder=-1 and @SortColumn='JournalTypeNumber')  THEN JournalTypeNumber END Desc
				
              
        
				OFFSET @RecordFrom ROWS         
				FETCH NEXT @PageSize ROWS ONLY   
	END
	ELSE
	BEGIN
			SELECT DISTINCT @HeadersIdValue = STRING_AGG(CBD.JournalBatchHeaderId, ', ')
			FROM [dbo].[CommonBatchDetails] CBD WITH(NOLOCK)  
			WHERE CBD.JournalTypeNumber like '%' + @JeNumber +'%';
	
			IF(@HeadersIdValue = '' OR @HeadersIdValue IS NULL)
			BEGIN
				SET @HeadersIdValue = '';
			END
			ELSE
			BEGIN
				SET @HeadersIdValue = (SELECT dbo.DistinctList(@HeadersIdValue,',') DistinctList)
			END

			;WITH CBD_Grouped AS
			(
				SELECT 
					JournalBatchHeaderId,
					SUM(DebitAmount) AS DebitAmount,
					SUM(CreditAmount) AS CreditAmount,
					JournalTypeNumber  
				FROM dbo.CommonBatchDetails WITH (NOLOCK)
				GROUP BY JournalBatchHeaderId,JournalTypeNumber
			),
		 Results AS(
		   SELECT JBH.[JournalBatchHeaderId]      
					,JBH.[BatchName]      
					,JBH.[CurrentNumber] 
					,(Cast(DBO.ConvertUTCtoLocal(JBH.[EntryDate],@CurrntEmpTimeZoneDesc)AS DATETIME)) as EntryDate
					,(Cast(DBO.ConvertUTCtoLocal(JBH.[PostDate],@CurrntEmpTimeZoneDesc)AS DATETIME)) as PostDate
					,JBH.[AccountingPeriod]      
					,JBH.[StatusId]      
					,JBH.[StatusName]      
					,JBH.[JournalTypeId]      
					,JBH.[JournalTypeName]      
					,CBD.[DebitAmount] AS TotalDebit    
				    ,CBD.[CreditAmount] as TotalCredit       
					,JBH.[TotalBalance]      
					,JBH.[MasterCompanyId]      
					,JBH.[CreatedBy]      
					,JBH.[UpdatedBy]      
					,(Cast(DBO.ConvertUTCtoLocal(JBH.[CreatedDate],@CurrntEmpTimeZoneDesc)AS DATETIME)) as CreatedDate
					,(Cast(DBO.ConvertUTCtoLocal(JBH.[UpdatedDate],@CurrntEmpTimeZoneDesc)AS DATETIME)) as UpdatedDate
					,JBH.[IsActive]      
					,JBH.[IsDeleted]  
					,JBH.[PostedBy]
					,JBH.[Module]  
			        ,CASE WHEN ISNULL(JBH.[TotalBalance],0) <> 0 THEN 'YES' ELSE 'NO' END AS IsError
					,CBD.[JournalTypeNumber]
				FROM [dbo].[BatchHeader] JBH WITH(NOLOCK)    
				INNER JOIN CBD_Grouped CBD ON JBH.JournalBatchHeaderId = CBD.JournalBatchHeaderId
				WHERE ((JBH.MasterCompanyId = @MasterCompanyId) AND (JBH.IsDeleted = @IsDeleted) AND (@StatusID=0 OR JBH.StatusId = @StatusID)
						AND JBH.JournalBatchHeaderId IN (SELECT Item FROM [dbo].[SplitString] (@HeadersIdValue,',')))    
		), ResultCount AS(SELECT COUNT(JournalBatchHeaderId) AS totalItems FROM Results)
		SELECT * INTO #TempResults FROM  Results
			WHERE (        
				(@GlobalFilter <>'' AND (        
				(BatchName like '%' +@GlobalFilter+'%') OR        
				(EntryDate like '%' +@GlobalFilter+'%') OR        
				(PostDate like '%' +@GlobalFilter+'%') OR        
				(AccountingPeriod like '%' +@GlobalFilter+'%') OR        
				(StatusName like '%'+@GlobalFilter+'%') OR        
				(JournalTypeName like '%'+@GlobalFilter+'%') OR        
				((CAST(TotalDebit AS NVARCHAR(20))) LIKE '%' +@GlobalFilter+'%') OR       
				((CAST(TotalCredit AS NVARCHAR(20))) LIKE '%' +@GlobalFilter+'%') OR       
				((CAST(TotalBalance AS NVARCHAR(20))) LIKE '%' +@GlobalFilter+'%') OR       
				(CreatedBy like '%' +@GlobalFilter+'%')  OR  
				(UpdatedBy like '%' +@GlobalFilter+'%')	OR
				(PostedBy like '%' +@GlobalFilter+'%') OR
				(JournalTypeNumber like '%' +@GlobalFilter+'%')
				))        
				OR           
				(@GlobalFilter='' AND (IsNull(@BatchName,'') ='' OR BatchName like '%' + @BatchName+'%') AND        
				(IsNull(@EntryDate,'') ='' OR (Cast(DBO.ConvertUTCtoLocal(EntryDate,@CurrntEmpTimeZoneDesc) as Date))=Cast(@EntryDate as date)) AND        
				(IsNull(@PostDate,'') ='' OR (Cast(DBO.ConvertUTCtoLocal(PostDate,@CurrntEmpTimeZoneDesc) as Date))=Cast(@PostDate as date)) AND        
				(IsNull(@AccountingPeriod,'') ='' OR AccountingPeriod like '%' + @AccountingPeriod+'%') AND        
				(IsNull(@StatusName,'') ='' OR StatusName like '%' + @StatusName+'%') AND        
				(IsNull(@JournalTypeName,'') ='' OR JournalTypeName like '%' + @JournalTypeName+'%') AND      
				(IsNull(@TotalDebit,'') ='' OR CAST(TotalDebit AS varchar(20)) like '%' + @TotalDebit+'%' ) AND       
				(IsNull(@TotalCredit,'') ='' OR CAST(TotalCredit AS varchar(20)) like '%' + @TotalCredit+'%' ) AND        
				(IsNull(@TotalBalance,'') ='' OR CAST(TotalBalance AS varchar(20)) like '%' + @TotalBalance+'%') AND       
				(IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND  
				(IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') AND
				(IsNull(@PostedBy,'') ='' OR PostedBy like '%' + @PostedBy+'%') 
				AND (IsNull(@IsError,'') ='' OR IsError like '%' + @IsError+'%')
				AND (IsNull(@JournalTypeNumber,'') ='' OR JournalTypeNumber like '%' + @JournalTypeNumber+'%')
				)      
		  )
		  SELECT @Count = COUNT(JournalBatchHeaderId) FROM #TempResults
		  SELECT *, @Count AS NumberOfItems FROM #TempResults ORDER BY          
				CASE WHEN (@SortOrder=1 and @SortColumn='JournalBatchHeaderId')  THEN JournalBatchHeaderId END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='BatchName')  THEN BatchName END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='EntryDate')  THEN EntryDate END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='PostDate')  THEN PostDate END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='AccountingPeriod')  THEN AccountingPeriod END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='StatusName')  THEN StatusName END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='JournalTypeName')  THEN JournalTypeName END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='TotalDebit')  THEN CAST(TotalDebit AS varchar(20)) END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='TotalCredit')  THEN CAST(TotalCredit AS varchar(20)) END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='TotalBalance')  THEN CAST(TotalBalance AS varchar(20)) END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='CreatedBy')  THEN CreatedBy END ASC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='PostedBy')  THEN PostedBy END ASC, 
				CASE WHEN (@SortOrder=1 and @SortColumn='IsError')  THEN IsError END ASC, 
				CASE WHEN (@SortOrder=1 and @SortColumn='JournalTypeNumber')  THEN JournalTypeNumber END ASC, 
        
				CASE WHEN (@SortOrder=-1 and @SortColumn='JournalBatchHeaderId')  THEN JournalBatchHeaderId END Desc,       
				CASE WHEN (@SortOrder=-1 and @SortColumn='BatchName')  THEN BatchName END Desc,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='EntryDate')  THEN EntryDate END Desc,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='PostDate')  THEN PostDate END Desc,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='AccountingPeriod')  THEN AccountingPeriod END Desc,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='StatusName')  THEN StatusName END Desc,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='JournalTypeName')  THEN JournalTypeName END Desc,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='TotalDebit')  THEN CAST(TotalDebit AS varchar(20))  END Desc,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='TotalCredit')  THEN CAST(TotalCredit AS varchar(20)) END Desc,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='TotalBalance')  THEN CAST(TotalBalance AS varchar(20)) END Desc,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedBy')  THEN CreatedBy END Desc,     
				CASE WHEN (@SortOrder=-1 and @SortColumn='UpdatedBy')  THEN UpdatedBy END Desc,
				CASE WHEN (@SortOrder=-1 and @SortColumn='PostedBy')  THEN PostedBy END Desc
				,CASE WHEN (@SortOrder=-1 and @SortColumn='IsError')  THEN IsError END Desc
				,CASE WHEN (@SortOrder=-1 and @SortColumn='JournalTypeNumber')  THEN JournalTypeNumber END Desc
              
        
				OFFSET @RecordFrom ROWS         
				FETCH NEXT @PageSize ROWS ONLY   
	END
	    
      
 END TRY          
 BEGIN CATCH      
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
        , @AdhocComments     VARCHAR(150)    = 'USP_GetJournalBatchListWithJEDetails'       
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))      
      + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100))       
      + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))      
      + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))      
      + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))      
      + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))      
      + '@Parameter7 = ''' + CAST(ISNULL(@BatchName, '') AS varchar(100))      
      + '@Parameter8 = ''' + CAST(ISNULL(@EntryDate, '') AS varchar(100))      
      + '@Parameter9 = ''' + CAST(ISNULL(@PostDate , '') AS varchar(100))      
      + '@Parameter10 = ''' + CAST(ISNULL(@AccountingPeriod , '') AS varchar(100))      
      + '@Parameter11 = ''' + CAST(ISNULL(@StatusName, '') AS varchar(100))      
      + '@Parameter12 = ''' + CAST(ISNULL(@JournalTypeName, '') AS varchar(100))      
     + '@Parameter13 = ''' + CAST(ISNULL(@TotalDebit, '') AS varchar(100))      
     + '@Parameter14 = ''' + CAST(ISNULL(@TotalCredit, '') AS varchar(100))      
     + '@Parameter15 = ''' + CAST(ISNULL(@TotalBalance , '') AS varchar(100))      
     + '@Parameter16 = ''' + CAST(ISNULL(@MasterCompanyId  , '') AS varchar(100))      
     + '@Parameter17 = ''' + CAST(ISNULL(@EmployeeId, '') AS varchar(100))       
     + '@Parameter18 = ''' + CAST(ISNULL(@IsDeleted  , '') AS varchar(100))      
     + '@Parameter19 = ''' + CAST(ISNULL(@CreatedBy, '') AS varchar(100))       
     + '@Parameter19 = ''' + CAST(ISNULL(@UpdatedBy, '') AS varchar(100))       
     + '@Parameter20 = ''' + CAST(ISNULL(@IsError, '') AS varchar(100))       
     + '@Parameter21 = ''' + CAST(ISNULL(@JournalTypeNumber, '') AS varchar(100))       
        , @ApplicationName VARCHAR(100) = 'PAS'      
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------      
        exec spLogException       
                @DatabaseName           = @DatabaseName      
                , @AdhocComments          = @AdhocComments      
                , @ProcedureParameters = @ProcedureParameters      
                , @ApplicationName        =  @ApplicationName      
                , @ErrorLogID                    = @ErrorLogID OUTPUT ;      
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)      
        RETURN(1);      
 END CATCH      
END