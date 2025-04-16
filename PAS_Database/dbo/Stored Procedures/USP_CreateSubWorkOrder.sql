/*************************************************************           
 ** File:		 [USP_CreateSubWorkOrder]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Create Sub Work Order.
 ** Purpose:         
 ** Date:   11-April-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    11-April-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_CreateSubWorkOrder] @SubWorkOrderId=0,@WorkOrderId=8651,@SubWorkOrderNo=N'CREATING',@MasterCompanyId=1,@CreatedBy=N'DANE PERK',@UpdatedBy=N'DANE PERK',
@CreatedDate='2025-04-15 11:15:07.360',@UpdatedDate='2025-04-15 11:15:07.360',@IsActive=1,@IsDeleted=0,@WorkOrderPartNumberId=8355,@OpenDate='2025-04-15 00:00:00',
@WorkOrderMaterialsId=52314,@StockLineId=199224,@SubWorkOrderStatusId=Null
**************************************************************/
CREATE PROCEDURE [dbo].[USP_CreateSubWorkOrder]
@SubWorkOrderId BIGINT = NULL,
@WorkOrderId BIGINT,
@SubWorkOrderNo VARCHAR(100),
@MasterCompanyId INT,
@CreatedBy VARCHAR(256),
@UpdatedBy VARCHAR(256),
@CreatedDate DATETIME2,
@UpdatedDate DATETIME2,
@IsActive BIT,
@IsDeleted BIT,
@WorkOrderPartNumberId BIGINT,
@OpenDate DATETIME2,
@WorkOrderMaterialsId BIGINT,
@StockLineId BIGINT,
@SubWorkOrderStatusId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
		
		-- Declare variables
		DECLARE @SubWorkOrderCodePrefix INT, @SubWorkOrderNum NVARCHAR(100);
		DECLARE @CodePrefix NVARCHAR(50), @CodeSuffix NVARCHAR(50), @CurrentNo BIGINT = 0;	

		-- Code Types Of CodePrefix	
		SELECT @SubWorkOrderCodePrefix = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='subworkorder';		
		SELECT TOP 1 @CodePrefix = [CodePrefix], @CodeSuffix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @SubWorkOrderCodePrefix AND [MasterCompanyId] = @MasterCompanyId;
		
/***************Start Save Sub WorkOrder Details***************/	
	
		IF(ISNULL(@SubWorkOrderId, 0) = 0)
		BEGIN
		
			/*************** Prefixes ***************/				
			IF (@CodePrefix IS NOT NULL AND @CodePrefix <> '')
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
					SET @CurrentNo = (SELECT ISNULL([StartsFrom], 0) FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId) + 1;
					UPDATE [dbo].[CodePrefixes]
					SET [CurrentNummber] = @CurrentNo 
					WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
				END
				-- Generate Sub WorkOrder Number
				SET @SubWorkOrderNum = (SELECT * FROM dbo.udfGenerateCodeNumber(@CurrentNo, ISNULL(@CodePrefix,''),ISNULL(@CodeSuffix, '')))
				
			END
			ELSE
			BEGIN
				-- Generate Sub WorkOrder Number
				SET @SubWorkOrderNum = (SELECT * FROM dbo.udfGenerateCodeNumber(@CurrentNo, '',''))
			END			
			/*****************End Prefixes*******************/
			
		INSERT INTO [DBO].[SubWorkOrder]([WorkOrderId], [SubWorkOrderNo], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
						[WorkOrderPartNumberId], [OpenDate], [WorkOrderMaterialsId], [StockLineId], [SubWorkOrderStatusId])
		VALUES (@WorkOrderId, @SubWorkOrderNum, @MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0,
					   @WorkOrderPartNumberId, @OpenDate, @WorkOrderMaterialsId,@StockLineId, @SubWorkOrderStatusId)
		
		SET @SubWorkOrderId = SCOPE_IDENTITY();

		END
		ELSE
		BEGIN

		UPDATE [DBO].[SubWorkOrder] 
		SET	[OpenDate] = @OpenDate, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
		WHERE [SubWorkOrderId] = @SubWorkOrderId AND [MasterCompanyId] = @MasterCompanyId		
				
		END

/***************End Save Sub WorkOrder Details***************/	
		
		SELECT SubWorkOrderId, SubWorkOrderNo FROM [DBO].[SubWorkOrder] WITH(NOLOCK) WHERE [SubWorkOrderId] = @SubWorkOrderId

	
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0  
		PRINT 'ROLLBACK'  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CreateSubWorkOrder'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END