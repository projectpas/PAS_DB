

/*************************************************************           
 ** File:   [USP_AddUpdateCustomerRfq]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used USP_AddUpdateCustomerRfq
 ** Purpose:         
 ** Date:   13/02/2023      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    13/02/2023  Amit Ghediya    Created
	2	 22-02-2024  Rajesh Gami     Complete the Insert call
     
-- EXEC USP_AddUpdateCustomerRfq
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddUpdateCustomerRfq]
	@tbl_CustomerRfqType CustomerRfqType READONLY,
	@MasterCompanyId INT,
	@CreatedBy VARCHAR(200)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRANSACTION;
	BEGIN TRY

					DECLARE @CustomerRfqId BIGINT;
		
		------------------- Customer RFQ add ---------------------------------------------------------
					IF OBJECT_ID(N'tempdb..#tmpCustomerRfq') IS NOT NULL
					BEGIN
						DROP TABLE #tmpCustomerRfq
					END
			
					CREATE TABLE #tmpCustomerRfq
					(
						ID BIGINT NOT NULL IDENTITY, 
						[RfqId] [BIGINT] NULL,
						[RfqCreatedDate] [DATETIME2](7) NULL,
						[IntegrationPortalId] [int] NULL,
						[Type] [VARCHAR](50) NULL,
						[Notes] [VARCHAR](100) NULL,
						[BuyerName] [VARCHAR](250) NULL,
						[BuyerCompanyName] [VARCHAR](250) NULL,
						[BuyerAddress] [VARCHAR](250) NULL,
						[BuyerCity] [VARCHAR](50) NULL,
						[BuyerCountry] [VARCHAR](50) NULL,
						[BuyerState] [VARCHAR](50) NULL,
						[BuyerZip] [VARCHAR](50) NULL,
						[LinePartNumber] [VARCHAR](250) NULL,
						[LineDescription] [VARCHAR](250) NULL,
						[CreatedBy] [VARCHAR](50) NOT NULL,
						[CreatedDate] [datetime2](7) NOT NULL,
						[UpdatedBy] [VARCHAR](50) NOT NULL,
						[UpdatedDate] [DATETIME2](7) NOT NULL,
						[IsActive] [BIT] NOT NULL,
						[IsDeleted] [BIT] NOT NULL,
						[AltPartNumber] [VARCHAR](250) NULL,
						[Quantity] [int] NULL,
							[Condition] [varchar](50) NULL
					)
					print 'STEP 1'
					INSERT INTO #tmpCustomerRfq ([RfqId] ,[RfqCreatedDate] ,[IntegrationPortalId],[Type] ,[Notes] ,[BuyerName] ,[BuyerCompanyName] ,[BuyerAddress] ,[BuyerCity] ,
						[BuyerCountry] ,[BuyerState] ,[BuyerZip] ,[LinePartNumber] ,[LineDescription] ,
						[CreatedBy] ,[CreatedDate] ,[UpdatedBy] ,[UpdatedDate] ,[IsActive] ,[IsDeleted],[AltPartNumber],[Quantity],Condition)
					SELECT [RfqId] 
					,RfqCreatedDate
					--,CASE WHEN [RfqCreatedDate] IS NOT NULL AND [RfqCreatedDate] != '' THEN CAST([RfqCreatedDate] AS DATETIME2) ELSE NULL END 
					,[IntegrationPortalId],[Type] ,[Notes] ,[BuyerName] ,[BuyerCompanyName] ,[BuyerAddress] ,[BuyerCity] ,
						   [BuyerCountry] ,[BuyerState] ,[BuyerZip] ,[LinePartNumber] ,[LineDescription] ,
						   @CreatedBy ,GETUTCDATE() ,@CreatedBy ,GETUTCDATE() ,1 ,0,AltPartNumber,Quantity,Condition
					FROM @tbl_CustomerRfqType;
				print 'STEP 2'
	  ------------------------------Delete record if exists---------------------------------------------------------------------
					DELETE c
						FROM [dbo].[CustomerRfq] c 
						INNER JOIN @tbl_CustomerRfqType tbl  ON c.RfqId=tbl.RfqId AND c.IntegrationPortalId = tbl.IntegrationPortalId
						WHERE c.MasterCompanyId = @MasterCompanyId
	 --------------------------- Insert into Rfq table --------------------------------------------------
				print 'STEP 3'
				--SELECT * FROM #tmpCustomerRfq
					INSERT INTO [dbo].[CustomerRfq]
							   ([RfqId] ,[RfqCreatedDate],[IntegrationPortalId] ,[Type] ,[Notes] ,[BuyerName] ,[BuyerCompanyName] ,[BuyerAddress] ,[BuyerCity] ,
								[BuyerCountry] ,[BuyerState] ,[BuyerZip] ,[LinePartNumber] ,[LineDescription] , 
								[MasterCompanyId] ,		
								[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted],[AltPartNumber],[Quantity],Condition)
					SELECT [RfqId] ,[RfqCreatedDate],[IntegrationPortalId],[Type] ,[Notes] ,[BuyerName] ,[BuyerCompanyName] ,[BuyerAddress] ,[BuyerCity] ,
						   [BuyerCountry] ,[BuyerState] ,[BuyerZip] ,[LinePartNumber] ,[LineDescription] ,
						   @MasterCompanyId ,
						   @CreatedBy,@CreatedBy ,GETUTCDATE() ,GETUTCDATE() ,1 ,0,AltPartNumber,Quantity,Condition
					 FROM #tmpCustomerRfq;
							print 'STEP 4'
					SELECT @CustomerRfqId = SCOPE_IDENTITY();
					COMMIT;
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			SELECT  
    ERROR_NUMBER() AS ErrorNumber  
    ,ERROR_SEVERITY() AS ErrorSeverity  
    ,ERROR_STATE() AS ErrorState  
    ,ERROR_PROCEDURE() AS ErrorProcedure  
    ,ERROR_LINE() AS ErrorLine  
    ,ERROR_MESSAGE() AS ErrorMessage;  
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_AddUpdateCustomerRfq' 
            , @ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100))
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