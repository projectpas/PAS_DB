/*************************************************************           
 ** File:		 [USP_CreateUpdateExportInfo]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Create or Update ExportInfo of Item Master.
 ** Purpose:         
 ** Date:   08-Oct-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    08-Oct-2025		Divyesh Kathiriya	Created  	
    
 -- EXEC [USP_CreateUpdateExportInfo] @ExportECCN=N'ECCNFull1',@ITARNumber=N'',@ExportUomId=6,@ExportValue=100,@ExportCurrencyId=2,@ExportWeight=2,@ExportWeightUnit=N'1',
                                      @ExportSizeLength=3,@ExportSizeWidth=4,@ExportSizeHeight=5,@ExportClassificationId=1,@ExportSizeUnitOfMeasureId=3,@IsIATR=1,@IsExportLicense=1,
                                      @ScheduleB=N'Schedule B',@HSCode=N'HS Code',@HTSCode=N'HTS Code',@ECCNDeterminationSourceID=13,@CreatedBy=N'dane park',@UpdatedBy=N'dane park',
                                      @MasterCompanyId=1,@ItemMasterId=97000
**************************************************************/
Create   PROCEDURE [DBO].[USP_CreateUpdateExportInfo]
@ExportECCN VARCHAR(200),
@ITARNumber VARCHAR(200) = NULL,
@ExportUomId BIGINT = NULL,
@ExportValue DECIMAL(18,2),
@ExportCurrencyId INT = NULL,
@ExportWeight DECIMAL(18,2) = NULL,
@ExportWeightUnit VARCHAR(50) = NULL,
@ExportSizeLength DECIMAL(18,2) = NULL,
@ExportSizeWidth DECIMAL(18,2) = NULL,
@ExportSizeHeight DECIMAL(18,2) = NULL,
@ExportClassificationId TINYINT = NULL,
@ExportSizeUnitOfMeasureId BIGINT = NULL,
@IsIATR BIT,
@IsExportLicense BIT,
@ScheduleB VARCHAR(15) = NULL,
@HSCode VARCHAR(15) = NULL,
@HTSCode VARCHAR(15) = NULL,
@ECCNDeterminationSourceID INT,
@CreatedBy VARCHAR(50),
@UpdatedBy VARCHAR(50),
@MasterCompanyId INT,
@ItemMasterId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
	
	DECLARE @ItemMasterExportInfoId BIGINT;

    -- Error Msg
	IF OBJECT_ID(N'tempdb..#tmpmsg') IS NOT NULL        
	BEGIN        
		DROP TABLE #tmpmsg    
	END   

	CREATE TABLE #tmpmsg
	(        
		msg VARCHAR(100) NULL    
	) 
/***************Start Save ItemMaster ExportInfo Details***************/
			
    IF EXISTS (SELECT 1 FROM [DBO].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @ItemMasterId)
    BEGIN        
        IF NOT EXISTS (SELECT 1 FROM [DBO].[ItemMasterExportInfo] WITH(NOLOCK) WHERE [ItemMasterId] = @ItemMasterId)
        BEGIN
            INSERT INTO [DBO].[ItemMasterExportInfo](
                [ItemMasterId],
                [MasterCompanyId],
                [ExportECCN],
                [ITARNumber],                
                [ExportValue],
                [ExportCurrencyId],
                [ExportWeight],
                [ExportWeightUnit],
                [ExportUomId],
                [ExportSizeLength],
                [ExportSizeHeight],
                [ExportSizeWidth],
                [ExportSizeUnitOfMeasureId],
                [ExportClassificationId],
                [CreatedBy],
                [CreatedDate],
                [UpdatedBy],
                [UpdatedDate],
                [IsActive],
                [IsDeleted],
                [IsIATR],
                [IsExportLicense],
                [ScheduleB],
                [HSCode],
                [HTSCode],
                [ECCNDeterminationSourceID]
            )
            VALUES
            (
                @ItemMasterId,
                @MasterCompanyId,
                @ExportECCN,
                @ITARNumber,                
                @ExportValue,
                @ExportCurrencyId,
                @ExportWeight,
                @ExportWeightUnit,
                @ExportUomId,
                @ExportSizeLength,
                @ExportSizeHeight,
                @ExportSizeWidth,
                @ExportSizeUnitOfMeasureId,
                @ExportClassificationId,
                @CreatedBy,
                GETUTCDATE(),
                @UpdatedBy,
                GETUTCDATE(),
                1,
                0,
                @IsIATR,
                @IsExportLicense,
                @ScheduleB,
                @HSCode,
                @HTSCode,
                @ECCNDeterminationSourceID
            );
            
            SET @ItemMasterExportInfoId = SCOPE_IDENTITY();

            EXEC [DBO].[UpdateItemMasterExportInfoDetails] @ItemMasterId;

/***************End Save ItemMaster ExportInfo Details***************/
	    END
	    ELSE
	    BEGIN
/***************Start Update ItemMaster ExportInfo Details***************/
		    UPDATE [DBO].[ItemMasterExportInfo]
            SET 
                [ExportECCN] = @ExportECCN,
                [ITARNumber] = @ITARNumber,                
                [ExportValue] = @ExportValue,
                [ExportCurrencyId] = @ExportCurrencyId,
                [ExportWeight] = @ExportWeight,
                [ExportWeightUnit] = @ExportWeightUnit,
                [ExportUomId] = @ExportUomId,
                [ExportSizeLength] = @ExportSizeLength,
                [ExportSizeHeight] = @ExportSizeHeight,
                [ExportSizeWidth] = @ExportSizeWidth,
                [ExportSizeUnitOfMeasureId] = @ExportSizeUnitOfMeasureId,
                [ExportClassificationId] = @ExportClassificationId,
                [UpdatedBy] = @UpdatedBy,
                [UpdatedDate] = GETUTCDATE(),                
                [IsIATR] = @IsIATR,
                [IsExportLicense] = @IsExportLicense,
                [ScheduleB] = @ScheduleB,
                [HSCode] = @HSCode,
                [HTSCode] = @HTSCode,
                [ECCNDeterminationSourceID] = @ECCNDeterminationSourceID
            WHERE [ItemMasterId] = @ItemMasterId;
         
            EXEC [DBO].[UpdateItemMasterExportInfoDetails] @ItemMasterId;
            
            SELECT @ItemMasterExportInfoId = [ItemMasterExportInfoId] FROM [DBO].[ItemMasterExportInfo] WITH(NOLOCK) WHERE [ItemMasterId] = @ItemMasterId

/***************End Update ItemMaster ExportInfo Details***************/		
	    END
    END
    ELSE
    BEGIN
		INSERT INTO #tmpmsg(msg) VALUES ('ItemMaster Id Does Not Exist.');					
	END    

    IF EXISTS (SELECT 1 FROM #tmpmsg)
	BEGIN
		SELECT msg FROM #tmpmsg;			          
	END
	ELSE
	BEGIN			
		SELECT @ItemMasterExportInfoId AS [ItemMasterExportInfoId];
	END		

	COMMIT TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CreateUpdateExportInfo'
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