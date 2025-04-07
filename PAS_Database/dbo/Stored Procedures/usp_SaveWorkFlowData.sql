/*************************************************************           
 ** File:   [usp_SaveWorkFlowData]           
 ** Author:   HEMANT SALIYA
 ** Description: This stored procedure is used to Create Work Order Quote
 ** Purpose:         
 ** Date:   04-April-2025        
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04-April-2025   BHARGAV SALIYA    Created
    
--   EXEC [usp_SaveWorkFlowData] 
**************************************************************/
CREATE   PROCEDURE [dbo].[usp_SaveWorkFlowData]
@MasterCompanyId INT,
@VersionNum VARCHAR(256),
@IsVersionIncrease BIT = NULL,
@tbl_WorkFloaddItemsType WorkFlowType READONLY
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

		-- Declare variables
		DECLARE @WorkFlowCodePrefix INT, @CurrentNo INT = 0,@WorkFlowVersion INT,@versionNo INT;;
		DECLARE @CodePrefix NVARCHAR(50),@CodeSuffix NVARCHAR(50),@VersionCodePrefix NVARCHAR(50),@VersionCodeSuffix NVARCHAR(50);
		DECLARE @WorkFlowNum VARCHAR(30) = NULL,@NewVersionNum VARCHAR(30) = NULL;
		DECLARE @WorkFlowid bigINT;

		-- Code Types Of CodePrefix	
		SELECT @WorkFlowCodePrefix = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='Workflow Id';
		SELECT @WorkFlowVersion = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='Version';
		
		SELECT TOP 1 @VersionCodePrefix = [CodePrefix], @VersionCodeSuffix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @WorkFlowVersion AND [MasterCompanyId] = @MasterCompanyId;
		SELECT TOP 1 @CodePrefix = [CodePrefix], @CodeSuffix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @WorkFlowCodePrefix AND [MasterCompanyId] = @MasterCompanyId;

		IF OBJECT_ID(N'tempdb..#Temp_Workflow') IS NOT NULL
		BEGIN
			DROP TABLE #Temp_Workflow
		END

		CREATE TABLE #Temp_Workflow (
			[ID] BIGINT NOT NULL IDENTITY,
			[WorkflowId] BIGINT NULL,
			[WorkflowDescription] NVARCHAR(500) NULL,
			[Version] NVARCHAR(10) NULL,
			[WorkScopeId] BIGINT NULL,
			[ItemMasterId] BIGINT NULL,
			[PartNumberDescription] NVARCHAR(MAX) NULL,
			[CustomerId] BIGINT NULL,
			[CurrencyId] INT NULL,
			[WorkflowExpirationDate] DATETIME NULL,
			[IsCalculatedBERThreshold] BIT NULL,
			[IsFixedAmount] BIT NULL,
			[FixedAmount] DECIMAL(18,2) NULL,
			[IsPercentageOfNew] BIT NULL,
			[CostOfNew] DECIMAL(18,2) NULL,
			[PercentageOfNew] BIT NULL,
			[IsPercentageOfReplacement] BIT NULL,
			[CostOfReplacement] DECIMAL(18,2) NULL,
			[PercentageOfReplacement] INT NULL,
			[Memo] NVARCHAR(MAX) NULL,
			[ManagementStructureId] BIGINT NULL,
			[MasterCompanyId] INT NULL,
			[CreatedBy] NVARCHAR(256) NULL,
			[UpdatedBy] NVARCHAR(256) NULL,
			[CreatedDate] DATETIME NULL,
			[UpdatedDate] DATETIME NULL,
			[IsActive] BIT NULL,
			[IsDeleted] BIT NULL,
			[PartNumber] NVARCHAR(256) NULL,
			[CustomerName] NVARCHAR(256) NULL,
			[FlatRate] DECIMAL(18,2) NULL,
			[BERThresholdAmount] DECIMAL(18,2) NULL,
			[WorkOrderNumber] NVARCHAR(256) NULL,
			[CustomerCode] NVARCHAR(100) NULL,
			[OtherCost] DECIMAL(18,2) NULL,
			[WorkflowCreateDate] DATETIME NULL,
			[ChangedPartNumberId] BIGINT NULL,
			[PercentageOfMaterial] INT NULL,
			[PercentageOfExpertise] INT NULL,
			[PercentageOfCharges] INT NULL,
			[PercentageOfOthers] INT NULL,
			[PercentageOfTotal] DECIMAL(18,2) NULL,
			[RevisedPartNumber] NVARCHAR(200) NULL,
			[ChangedPartNumberDescription] NVARCHAR(200) NULL,
			[ChangedPartNumber] NVARCHAR(200) NULL,
			[WorkScope] NVARCHAR(100) NULL,
			[Currency] NVARCHAR(100) NULL,
			[WFParentId] BIGINT NULL,
			[IsVersionIncrease] BIT NULL
		);

		-- Generate Work Flow version
		IF(@IsVersionIncrease = 1)
		BEGIN
			IF (@VersionNum IS NOT NULL AND @VersionNum <> '')
			BEGIN
				IF LEN(@VersionNum) > 5
				BEGIN
					-- Split by '-' and take second part
					DECLARE @splitPos INT = CHARINDEX('-', @VersionNum);
					IF @splitPos > 0
					BEGIN
						SET @versionNo = CAST(SUBSTRING(@VersionNum, @splitPos + 1, LEN(@VersionNum)) AS INT) + 1;
					END
				END
				ELSE
				BEGIN
					-- Take substring from position 3
					SET @versionNo = CAST(SUBSTRING(@VersionNum, 3, LEN(@VersionNum)) AS INT) + 1;
				END

				SELECT @versionNo AS NewVersionNumber;

				SET @NewVersionNum = (SELECT * FROM dbo.udfGenerateCodeNumber(@versionNo, ISNULL(@VersionCodePrefix,''),ISNULL(@VersionCodeSuffix, '')))
			END
			else
			begin
				SET @NewVersionNum = (SELECT * FROM dbo.udfGenerateCodeNumber(1, ISNULL(@VersionCodePrefix,''),ISNULL(@VersionCodeSuffix, '')))
			end
		END
		SET @NewVersionNum = CASE WHEN @NewVersionNum <> ''  THEN @NewVersionNum else ISNULL(@VersionNum,'') END;

		-- Check for current number and increment
		IF @CodePrefix IS NOT NULL AND @CodePrefix <> ''
		BEGIN
			SELECT @CurrentNo = ISNULL([CurrentNummber], 0) FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;        
			IF @CurrentNo > 0
			BEGIN
				SET @CurrentNo = @CurrentNo + 1;
				UPDATE [dbo].[CodePrefixes] 
				SET [CurrentNummber] = @CurrentNo
				WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
			END
			ELSE
			BEGIN
				SET @CurrentNo = (SELECT ISNULL([StartsFrom], 0)  FROM [dbo].[CodePrefixes] WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId) + 1;
				UPDATE [dbo].[CodePrefixes]
				SET [CurrentNummber] = @CurrentNo 
				WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
			END
			-- Generate Work Flow Number
			SET @WorkFlowNum = (SELECT * FROM dbo.udfGenerateCodeNumber(@CurrentNo, ISNULL(@CodePrefix,''),ISNULL(@CodeSuffix, '')))
		END
		ELSE
		BEGIN
			-- Generate Work Flow Number
			SET @WorkFlowNum = (SELECT * FROM dbo.udfGenerateCodeNumber(@CurrentNo, '',''))
		END


		INSERT INTO #Temp_Workflow (
			[WorkflowId], [WorkflowDescription], [Version], [WorkScopeId], [ItemMasterId],
			[PartNumberDescription], [CustomerId], [CurrencyId], [WorkflowExpirationDate], [IsCalculatedBERThreshold],
			[IsFixedAmount], [FixedAmount], [IsPercentageOfNew], [CostOfNew], [PercentageOfNew],
			[IsPercentageOfReplacement], [CostOfReplacement], [PercentageOfReplacement], [Memo], [ManagementStructureId],
			[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],
			[IsActive], [IsDeleted], [PartNumber], [CustomerName], [FlatRate],
			[BERThresholdAmount], [WorkOrderNumber], [CustomerCode], [OtherCost], [WorkflowCreateDate],
			[ChangedPartNumberId], [PercentageOfMaterial], [PercentageOfExpertise], [PercentageOfCharges], [PercentageOfOthers],
			[PercentageOfTotal], [RevisedPartNumber], [ChangedPartNumberDescription], [ChangedPartNumber], [WorkScope],
			[Currency], [WFParentId], [IsVersionIncrease]
		)
		SELECT 
			[WorkflowId], [WorkflowDescription], @NewVersionNum, [WorkScopeId], [ItemMasterId],
			[PartNumberDescription], [CustomerId], [CurrencyId], [WorkflowExpirationDate], [IsCalculatedBERThreshold],
			[IsFixedAmount], [FixedAmount], [IsPercentageOfNew], [CostOfNew], [PercentageOfNew],
			[IsPercentageOfReplacement], [CostOfReplacement], [PercentageOfReplacement], [Memo], [ManagementStructureId],
			[MasterCompanyId], [CreatedBy], [UpdatedBy], GETUTCDATE(), GETUTCDATE(),
			[IsActive], [IsDeleted], [PartNumber], [CustomerName], [FlatRate],
			[BERThresholdAmount], @WorkFlowNum, [CustomerCode], [OtherCost], [WorkflowCreateDate],
			[ChangedPartNumberId], [PercentageOfMaterial], [PercentageOfExpertise], [PercentageOfCharges], [PercentageOfOthers],
			[PercentageOfTotal], [RevisedPartNumber], [ChangedPartNumberDescription], [ChangedPartNumber], [WorkScope],
			[Currency], [WFParentId], [IsVersionIncrease]
		FROM @tbl_WorkFloaddItemsType;  

		--SELECT * FROM  #Temp_Workflow

		INSERT INTO [dbo].Workflow(
			[WorkflowDescription], [Version], [WorkScopeId], [ItemMasterId],
			[PartNumberDescription], [CustomerId], [CurrencyId], [WorkflowExpirationDate], [IsCalculatedBERThreshold],
			[IsFixedAmount], [FixedAmount], [IsPercentageOfNew], [CostOfNew], [PercentageOfNew],
			[IsPercentageOfReplacement], [CostOfReplacement], [PercentageOfReplacement], [Memo], [ManagementStructureId],
			[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],
			[IsActive], [IsDeleted], [PartNumber], [CustomerName], [FlatRate],
			[BERThresholdAmount], [WorkOrderNumber], [CustomerCode], [OtherCost], [WorkflowCreateDate],
			[ChangedPartNumberId], [PercentageOfMaterial], [PercentageOfExpertise], [PercentageOfCharges], [PercentageOfOthers],
			[PercentageOfTotal], [RevisedPartNumber], [ChangedPartNumberDescription], [ChangedPartNumber], [WorkScope],
			[Currency], [WFParentId], [IsVersionIncrease]
		)
		SELECT 
			[WorkflowDescription], [Version], [WorkScopeId], [ItemMasterId],
			[PartNumberDescription], [CustomerId], [CurrencyId], [WorkflowExpirationDate], [IsCalculatedBERThreshold],
			[IsFixedAmount], [FixedAmount], [IsPercentageOfNew], [CostOfNew], [PercentageOfNew],
			[IsPercentageOfReplacement], [CostOfReplacement], [PercentageOfReplacement], [Memo], [ManagementStructureId],
			[MasterCompanyId], [CreatedBy], [UpdatedBy], GETUTCDATE(), GETUTCDATE(),
			[IsActive], [IsDeleted], [PartNumber], [CustomerName], [FlatRate],
			[BERThresholdAmount], @WorkFlowNum, [CustomerCode], [OtherCost], [WorkflowCreateDate],
			[ChangedPartNumberId], [PercentageOfMaterial], [PercentageOfExpertise], [PercentageOfCharges], [PercentageOfOthers],
			[PercentageOfTotal], [RevisedPartNumber], [ChangedPartNumberDescription], [ChangedPartNumber], [WorkScope],
			[Currency], [WFParentId], [IsVersionIncrease]
		FROM #Temp_Workflow temp where temp.[WorkflowId] = 0;  

		set @WorkFlowid = SCOPE_IDENTITY();

		SELECT * from [dbo].Workflow wf with (nolock) where wf.WorkflowId = @WorkFlowid
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH        
	IF @@trancount > 0  
    PRINT 'ROLLBACK'  
		ROLLBACK TRAN;  
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
		, @AdhocComments     VARCHAR(150)    = 'usp_SaveWorkFlowData'   
		, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''  
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