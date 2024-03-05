-- =============================================
-- Author:		<Ayesha Sultana>
-- Create date: <3-11-2023>
-- Description:	<This SP is to copy selected Reporting Structure>
-- =============================================

 /*********************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author					Change Description              
 ** --   --------		 -------				--------------------------------            
 1		03-11-2023		Ayesha Sultana				 Created  
 2		16-11-2023		Ayesha Sultana				 Modified - version number bug fix 
 3		20-11-2023		Ayesha Sultana				 Modified - Reporting straucture name and date update 
 4		23-11-2023		Ayesha Sultana				 Modified - GLACCMAPPING bug fixes
 5		23-11-2023		Moin Bloch				     Modified - Renamed ReportingStructureId To NewReportingStructureId
 6		02-01-2023		Moin Bloch				     Modified - Resolved Copy Reporting Structure Issue
  
************************************************************************/ 

CREATE        PROCEDURE [dbo].[CopyReportingStructure]
@ReportingStructureId BIGINT,
@ReportName VARCHAR(50),  
@ReportDescription VARCHAR(500),
@CreatedBy VARCHAR(50),
@UpdatedBy VARCHAR(50),
@CreatedDate DATETIME,
@UpdatedDate DATETIME
AS
BEGIN
	SET NOCOUNT ON;      
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED       
	BEGIN TRY 
	BEGIN TRANSACTION
	BEGIN

	    DECLARE @TotalRecord int = 0;   
	    DECLARE @MinId BIGINT = 1;  
		DECLARE @LeafNodeId BIGINT = 0; 
		DECLARE @ParentId BIGINT = 0;
		DECLARE @NewLeafNodeId BIGINT = 0;
	
		INSERT INTO ReportingStructure([ReportName],[ReportDescription],[IsVersionIncrease],[VersionNumber],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[GlAccountClassId],[IsDefault])	
		SELECT ReportName=@ReportName,ReportDescription=@ReportDescription,IsVersionIncrease, VersionNumber='VER-000001',MasterCompanyId,CreatedBy=@CreatedBy,UpdatedBy=@UpdatedBy,CreatedDate=@CreatedDate,UpdatedDate=@UpdatedDate,IsActive,IsDeleted,GlAccountClassId,IsDefault
		FROM [dbo].[ReportingStructure] WITH(NOLOCK)
		WHERE [ReportingStructureId] = @ReportingStructureId; 

		DECLARE @updatedReportingStructureId BIGINT;
		SELECT @updatedReportingStructureId = [ReportingStructureId] FROM ReportingStructure

		IF OBJECT_ID(N'tempdb..#tempLeafNodeTable') IS NOT NULL
		BEGIN
		    DROP TABLE #tempLeafNodeTable
		END
		  
		CREATE TABLE #tempLeafNodeTable 
		(
		    [ID] [bigint] NOT NULL IDENTITY (1, 1),
		    [LeafNodeId] [bigint] NULL,
			[Name] [varchar](256) NOT NULL,
			[ParentId] [bigint] NULL,
			[IsLeafNode] [bit] NULL,
			[GLAccountId] [varchar](MAX) NULL,
			[MasterCompanyId] [int] NOT NULL,
			[CreatedBy] [varchar](256) NOT NULL,
			[UpdatedBy] [varchar](256) NOT NULL,
			[CreatedDate] [datetime2](7) NOT NULL,
			[UpdatedDate] [datetime2](7) NOT NULL,
			[IsActive] [bit] NOT NULL,
			[IsDeleted] [bit] NOT NULL,
			[ReportingStructureId] [bigint] NULL,
			[IsPositive] [bit] NULL,
			[SequenceNumber] [bigint] NULL,
			[TempLeafNodeId] [bigint] NULL
		)

		INSERT INTO #tempLeafNodeTable ([LeafNodeId],[Name],[ParentId],[IsLeafNode],[GLAccountId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate]
                                       ,[UpdatedDate],[IsActive],[IsDeleted],[ReportingStructureId],[IsPositive],[SequenceNumber],[TempLeafNodeId])
                                 SELECT [LeafNodeId],[Name],[ParentId],[IsLeafNode],[GLAccountId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate]
								       ,[UpdatedDate],[IsActive],[IsDeleted],[ReportingStructureId]=@updatedReportingStructureId,[IsPositive],[SequenceNumber],NULL
		                           FROM [dbo].[LeafNode] WITH(NOLOCK) WHERE [ReportingStructureId] = @ReportingStructureId;

		SELECT @TotalRecord = COUNT(*), @MinId = MIN(ID) FROM #tempLeafNodeTable   

		WHILE @MinId <= @TotalRecord
		BEGIN	
			SELECT @LeafNodeId = [LeafNodeId],
			       @ParentId = [ParentId]		    
			FROM #tempLeafNodeTable WHERE [ID] = @MinId;

			INSERT INTO [dbo].[LeafNode]([Name],[ParentId],[IsLeafNode],[GLAccountId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[ReportingStructureId],[IsPositive],[SequenceNumber])
			                        SELECT [Name],[ParentId],[IsLeafNode],[GLAccountId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],@updatedReportingStructureId,[IsPositive],[SequenceNumber]
		    FROM #tempLeafNodeTable WHERE [LeafNodeId] = @LeafNodeId;
								
			SET @NewLeafNodeId = SCOPE_IDENTITY();
				
			UPDATE #tempLeafNodeTable SET [TempLeafNodeId] = @NewLeafNodeId WHERE [ID] = @MinId;

			IF(@ParentId > 0)
			BEGIN
				UPDATE [dbo].[LeafNode] SET [ParentId] = (SELECT [TempLeafNodeId] FROM #tempLeafNodeTable WHERE [LeafNodeId] = @ParentId) WHERE [LeafNodeId] = @NewLeafNodeId;
			END
			
			INSERT INTO GLAccountLeafNodeMapping([LeafNodeId],[GLAccountId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsPositive],[NewReportingStructureId],SequenceNumber)
		    SELECT @NewLeafNodeId,G.[GLAccountId],G.[MasterCompanyId],G.[CreatedBy],G.[UpdatedBy],G.[CreatedDate],G.[UpdatedDate],G.[IsActive],G.[IsDeleted],G.[IsPositive],@updatedReportingStructureId,SequenceNumber
		    FROM [dbo].[GLAccountLeafNodeMapping] G WITH(NOLOCK) 
		    WHERE [LeafNodeId] = @LeafNodeId;

			SET @MinId = @MinId + 1;
		END	
	END

	COMMIT  TRANSACTION
		
	END TRY  
	BEGIN CATCH  
	    IF @@trancount > 0
	    ROLLBACK TRAN;
		DECLARE @ErrorLogID INT ,@DatabaseName VARCHAR(100) = db_name()      
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
		,@AdhocComments VARCHAR(150) = 'CopyReportingStructure'      
		,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReportingStructureId, '') AS varchar(100))      
											+ '@Parameter2 = ''' + CAST(ISNULL(@ReportName, '') AS varchar(100))       
											+ '@Parameter3 = ''' + CAST(ISNULL(@ReportDescription, '') AS varchar(100))      
		,@ApplicationName VARCHAR(100) = 'PAS'      
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------      
		EXEC spLogException @DatabaseName = @DatabaseName      
								,@AdhocComments = @AdhocComments      
								,@ProcedureParameters = @ProcedureParameters      
								,@ApplicationName = @ApplicationName      
								,@ErrorLogID = @ErrorLogID OUTPUT;          
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)      
      
		RETURN (1);    
	END CATCH 
END