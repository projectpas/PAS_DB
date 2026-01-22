--EXEC LeafNodeLis 10,1,'ReceivingReconciliationId',1,'','',0,0,0,'ALL','',NULL,NULL,1,73
CREATE PROCEDURE [dbo].[LeafNodeList]
	-- Add the parameters for the stored procedure here
	@PageSize int,
	@PageNumber int,
	@SortColumn varchar(50)=null,
	@SortOrder int,
	@StatusID int,
	@GlobalFilter varchar(50) = null,
	@Name varchar(50)=null,
	@ParentNodeName varchar(50)=null,
	@GLAccount varchar(50)=null,
	@MasterCompanyId int = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @IsActive bit=1
				DECLARE @RecordFrom int;
				SET @RecordFrom = (@PageNumber-1) * @PageSize;
				IF @SortColumn is null
				Begin
					Set @SortColumn=Upper('CreatedDate')
				End 
				Else
				Begin 
					Set @SortColumn=Upper(@SortColumn)
				End
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
				Select RRH.LeafNodeId,RRH.[Name],RRH.[ParentId],RRH.IsLeafNode,RRH.GLAccountId,gl.AccountCode + '-' + gl.AccountName as GLAccount,lf.[Name] as 'ParentNodeName',
				RRH.MasterCompanyId,RRH.CreatedBy,RRH.CreatedDate,RRH.UpdatedBy,RRH.UpdatedDate,RRH.IsActive,RRH.IsDeleted
				from DBO.LeafNode RRH
				LEFT JOIN DBO.GLAccount gl WITH(NOLOCK) ON RRH.GLAccountId = gl.GLAccountId
				LEFT JOIN DBO.LeafNode lf WITH(NOLOCK) ON RRH.ParentId = lf.LeafNodeId
				Where ((@IsActive IS NULL OR RRH.IsActive=@IsActive))
					AND RRH.MasterCompanyId=@MasterCompanyId),
				FinalResult AS (
				SELECT LeafNodeId, [Name], [ParentId], IsLeafNode, GLAccountId, GLAccount,ParentNodeName, MasterCompanyId, CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted FROM Result
				where (
					(@GlobalFilter <>'' AND (([Name] like '%' +@GlobalFilter+'%' ) OR 
							(GLAccount like '%' +@GlobalFilter+'%') OR
							(ParentNodeName like '%' +@GlobalFilter+'%')
							))
							OR   
							(@GlobalFilter='' AND (IsNull(@Name,'') ='' OR [Name] like  '%'+ @Name+'%') and 
							--(IsNull(@Status,'') ='' OR Status like '%'+@Status+'%') and
							(IsNull(@GLAccount,'') ='' OR GLAccount like '%'+ @GLAccount+'%') and
							(IsNull(@ParentNodeName,'') ='' OR ParentNodeName like '%'+@ParentNodeName+'%'))
							)),
						ResultCount AS (Select COUNT(LeafNodeId) AS NumberOfItems FROM FinalResult)
						SELECT LeafNodeId, [Name], [ParentId], IsLeafNode, GLAccountId, GLAccount,ParentNodeName, MasterCompanyId, CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted, NumberOfItems FROM FinalResult, ResultCount

						ORDER BY  
					CASE WHEN (@SortOrder=1 and @SortColumn='LEAFNODEID')  THEN LeafNodeId END DESC,
					CASE WHEN (@SortOrder=1 and @SortColumn='NAME')  THEN [Name] END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='GLACCOUNT')  THEN GLAccount END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARENTNODENAME')  THEN ParentNodeName END ASC,

					CASE WHEN (@SortOrder=-1 and @SortColumn='LEAFNODEID')  THEN LeafNodeId END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='NAME')  THEN [Name] END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='GLACCOUNT')  THEN GLAccount END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARENTNODENAME')  THEN ParentNodeName END DESC
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
              , @AdhocComments     VARCHAR(150)    = 'LeafNodeLis' 
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