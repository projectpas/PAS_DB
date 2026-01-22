
/*************************************************************           
 ** File:   [USP_GetDistributionCodeList]           
 ** Author:   Subhash Saliya
 ** Description: Get Search Data for USP_GetDistributionCodeList  
 ** Purpose:         
 ** Date:   07/29/2022        
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/29/2022   Subhash Saliya Created

     
 EXECUTE [USP_GetDistributionCodeList] 5
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetDistributionCodeList]
	-- Add the parameters for the stored procedure here
	@PageNumber INT,
	@PageSize INT,
	@SortColumn VARCHAR(50)=null,
	@SortOrder INT,
	@StatusID INT,
	@GlobalFilter VARCHAR(50) = null,
	@CodeName VARCHAR(50)=null,
	@Description VARCHAR(50)=null,
	@GLAccountName VARCHAR(50)=null,
	@JournalTypeName VARCHAR(50)=null,
    @IsDeleted BIT = null,
	@MasterCompanyId INT = null,
	@DistributionId INT = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @RecordFrom INT;
				DECLARE @IsActive bit=1
				SET @RecordFrom = (@PageNumber-1) * @PageSize;
				IF @IsDeleted is null
				BEGIN
					SET @IsDeleted=0
				END
				
				IF @SortColumn is null
				BEGIN
					SET @SortColumn=Upper('DistributionId')
				END 
				Else
				BEGIN 
					SET @SortColumn=Upper(@SortColumn)
				END

				IF @StatusID=0
		         BEGIN 
		         	SET @IsActive=0
		         END 
		         ELSE IF @StatusID=1
		         BEGIN 
		         	SET @IsActive=1
		         END 
		         ELSE IF @StatusID=2
		         BEGIN 
		         	SET @IsActive=NULL
		         END

		
			;With Result AS(
				SELECT 
				      [DistributionId]
                     ,[JournalTypeID]
                     ,[JournalTypeName]
                     ,[CodeName]
                     ,[Description]
                     ,[GLAccountId]
                     ,[GLAccountName]
                     ,[Level1Id]
                     ,[Level1Name]
					 ,Level2Id
                     ,case when Level2Id =0 then '?' else Level2Name end as 'Level2Name'
                      ,[Level3Id]
                      ,case when Level3Id =0 then '?' else Level3Name end as [Level3Name]
                      ,[Level4Id]
                      ,case when Level4Id =0 then '?' else Level4Name end as [Level4Name]
                      ,[Level5Id]
                      ,case when Level5Id =0 then '?' else Level5Name end as [Level5Name]
                      ,[Level6Id]
                      ,case when Level6Id =0 then '?' else Level6Name end as [Level6Name]
                      ,[Level7Id]
                      ,case when Level7Id =0 then '?' else Level7Name end as [Level7Name]
                      ,[Level8Id]
                      ,case when Level8Id =0 then '?' else Level8Name end as [Level8Name]
                      ,[Level9Id]
                      ,case when Level9Id =0 then '?' else Level9Name end as [Level9Name]
                      ,[Level10Id]
                      ,case when Level10Id =0 then '?' else Level10Name end as [Level10Name]
                     ,[MasterCompanyId]
                     ,[CreatedBy]
                     ,[UpdatedBy]
                     ,[CreatedDate]
                     ,[UpdatedDate]
                     ,[IsActive]
                     ,[IsDeleted]
				FROM DistributionCodeEntry DC WITH (NOLOCK)
				WHERE (DC.IsDeleted = @IsDeleted) AND (@IsActive IS NULL OR DC.IsActive=@IsActive) AND DC.MasterCompanyId = @MasterCompanyId),
				FinalResult AS (
				SELECT [DistributionId]
                     ,[JournalTypeID]
                     ,[JournalTypeName]
                     ,[CodeName]
                     ,[Description]
                     ,[GLAccountId]
                     ,[GLAccountName]
                     ,[Level1Id]
                     ,[Level1Name]
                     ,[Level2Id]
                     ,[Level2Name]
                     ,[Level3Id]
                     ,[Level3Name]
                     ,[Level4Id]
                     ,[Level4Name]
                     ,[Level5Id]
                     ,[Level5Name]
                     ,[Level6Id]
                     ,[Level6Name]
                     ,[Level7Id]
                     ,[Level7Name]
                     ,[Level8Id]
                     ,[Level8Name]
                     ,[Level9Id]
                     ,[Level9Name]
                     ,[Level10Id]
                     ,[Level10Name]
                     ,[MasterCompanyId]
                     ,[CreatedBy]
                     ,[UpdatedBy]
                     ,[CreatedDate]
                     ,[UpdatedDate]
                     ,[IsActive]
                     ,[IsDeleted] FROM Result
				WHERE (
					(@GlobalFilter <>'' AND ((JournalTypeName like '%' +@GlobalFilter+'%' ) OR 
							(CodeName like '%' +@GlobalFilter+'%') OR
							(Description like '%' +@GlobalFilter+'%') OR
							(GLAccountName like '%' +@GlobalFilter+'%') 
							))
							OR   
							(@GlobalFilter='' AND (IsNull(@JournalTypeName,'') ='' OR JournalTypeName like  '%'+ @JournalTypeName+'%') and 
							(IsNull(@CodeName,'') ='' OR CodeName like '%'+@CodeName+'%') and
							(IsNull(@Description,'') ='' OR Description like  '%'+@Description+'%') and
							(IsNull(@GLAccountName,'') ='' OR GLAccountName like '%'+@GLAccountName+'%'))
							
							)),
						ResultCount AS (Select COUNT(DistributionId) AS NumberOfItems FROM FinalResult)
						SELECT [DistributionId]
                            ,[JournalTypeID]
                            ,[JournalTypeName]
                            ,[CodeName]
                            ,[Description]
                            ,[GLAccountId]
                            ,[GLAccountName]
                            ,[Level1Id]
                            ,[Level1Name]
                            ,[Level2Id]
                            ,[Level2Name]
                            ,[Level3Id]
                            ,[Level3Name]
                            ,[Level4Id]
                            ,[Level4Name]
                            ,[Level5Id]
                            ,[Level5Name]
                            ,[Level6Id]
                            ,[Level6Name]
                            ,[Level7Id]
                            ,[Level7Name]
                            ,[Level8Id]
                            ,[Level8Name]
                            ,[Level9Id]
                            ,[Level9Name]
                            ,[Level10Id]
                            ,[Level10Name]
                            ,[MasterCompanyId]
                            ,[CreatedBy]
                            ,[UpdatedBy]
                            ,[CreatedDate]
                            ,[UpdatedDate]
                            ,[IsActive]
                            ,[IsDeleted]
					        ,NumberOfItems FROM FinalResult, ResultCount

						ORDER BY  
					CASE WHEN (@SortOrder=1 and @SortColumn='DistributionId')  THEN DistributionId END DESC,
					CASE WHEN (@SortOrder=1 and @SortColumn='JournalTypeName')  THEN JournalTypeName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CodeName')  THEN CodeName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Description')  THEN Description END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='GLAccountName')  THEN GLAccountName END ASC,

					CASE WHEN (@SortOrder=-1 and @SortColumn='DistributionId')  THEN DistributionId END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='JournalTypeName')  THEN JournalTypeName END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CodeName')  THEN CodeName END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Description')  THEN Description END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='GLAccountName')  THEN GLAccountName END DESC
					
					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY
				END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetDistributionCodeList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END