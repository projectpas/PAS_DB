
/****** Object:  UserDefinedTableType [dbo].[CustomerRfqType]    Script Date: 14/02/2023 04:52:18 ******/
--CREATE TYPE [dbo].[CustomerRfqType] AS TABLE(
--	[RfqId] [bigint] NULL,
--	[RfqCreatedDate] [datetime2](7) NULL,
--	[Type] [varchar](50) NULL,
--	[Notes] [varchar](100) NULL,
--	[BuyerName] [varchar](250) NULL,
--	[BuyerCompanyName] [varchar](250) NULL,
--	[BuyerAddress] [varchar](250) NULL,
--	[BuyerCity] [varchar](50) NULL,
--	[BuyerCountry] [varchar](50) NULL,
--	[BuyerState] [varchar](50) NULL,
--	[BuyerZip] [varchar](50) NULL,
--	[LinePartNumber] [VARCHAR](250) NULL,
--	[LineDescription] [VARCHAR](250) NULL
--)
--GO

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
     
-- EXEC USP_AddUpdateCustomerRfq
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddUpdateCustomerRfq]
	@tbl_CustomerRfqType CustomerRfqType READONLY,
	@MasterCompanyId INT,
	@CreatedBy VARCHAR(200),
	@UpdatedBy VARCHAR(200),
	@CreatedDate DATETIME,
	@UpdatedDate DATETIME
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
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
					)

					INSERT INTO #tmpCustomerRfq ([RfqId] ,[RfqCreatedDate] ,[Type] ,[Notes] ,[BuyerName] ,[BuyerCompanyName] ,[BuyerAddress] ,[BuyerCity] ,
						[BuyerCountry] ,[BuyerState] ,[BuyerZip] ,[LinePartNumber] ,[LineDescription] ,
						[CreatedBy] ,[CreatedDate] ,[UpdatedBy] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
					SELECT [RfqId] ,[RfqCreatedDate] ,[Type] ,[Notes] ,[BuyerName] ,[BuyerCompanyName] ,[BuyerAddress] ,[BuyerCity] ,
						   [BuyerCountry] ,[BuyerState] ,[BuyerZip] ,[LinePartNumber] ,[LineDescription] ,
						   @CreatedBy ,GETDATE() ,@UpdatedBy ,GETDATE() ,1 ,0
					FROM @tbl_CustomerRfqType;
					
	  ------------------------------Delete record if exists---------------------------------------------------------------------

					--IF EXISTS(SELECT [RfqId] FROM [dbo].[CustomerRfq])
					--BEGIN
					--	DELETE FROM [dbo].[CustomerRfq];
					--END

	 --------------------------- Insert into Rfq table --------------------------------------------------
					
					--INSERT INTO [dbo].[CustomerRfq]
					--		   ([RfqId] ,[RfqCreatedDate] ,[Type] ,[Notes] ,[BuyerName] ,[BuyerCompanyName] ,[BuyerAddress] ,[BuyerCity] ,
					--			[BuyerCountry] ,[BuyerState] ,[BuyerZip] ,[LinePartNumber] ,[LineDescription] , 
					--			[MasterCompanyId] ,		
					--			[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
					--SELECT [RfqId] ,[RfqCreatedDate] ,[Type] ,[Notes] ,[BuyerName] ,[BuyerCompanyName] ,[BuyerAddress] ,[BuyerCity] ,
					--	   [BuyerCountry] ,[BuyerState] ,[BuyerZip] ,[LinePartNumber] ,[LineDescription] ,
					--	   @MasterCompanyId ,
					--	   @CreatedBy ,GETDATE() ,@UpdatedBy ,GETDATE() ,1 ,0
					-- FROM #tmpCustomerRfq;
					
					--SELECT @CustomerRfqId = SCOPE_IDENTITY();

    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
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