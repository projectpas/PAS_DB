/*************************************************************           
 ** File:		 [USP_CreateUpdateLegalEntityShipVia]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Create LegalEntity Shipping Address.
 ** Purpose:         
 ** Date:   19-June-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    19-June-2025		Divyesh Kathiriya	Created	
	2	 20-June-2025		Divyesh Kathiriya	Add Update Functionality of LegalEntity ShippingVia Detail.
    
 -- EXEC [USP_CreateUpdateLegalEntityShipVia] 
**************************************************************/
Create   PROCEDURE [DBO].[USP_CreateUpdateLegalEntityShipVia]
@LegalEntityShippingId BIGINT,
@legalEntityShippingAddressId BIGINT,
@LegalEntityId BIGINT,
@ShipVia VARCHAR(400),
@ShipViaId BIGINT,
@ShippingAccountInfo VARCHAR(200),
@ShippingTermsId BIGINT = NULL,
@Memo NVARCHAR(max),
@IsPrimary BIT,
@MasterCompanyId INT,
@CreatedBy VARCHAR(256),
@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

		-- Error Msg
		IF OBJECT_ID(N'tempdb..#tmpmsg') IS NOT NULL        
		BEGIN        
			DROP TABLE #tmpmsg    
		END   

		CREATE TABLE #tmpmsg
		(        
			msg VARCHAR(256) NULL 
		)

/***************Start Save LegalEntity Ship Via Details.***************/
		IF(ISNULL(@LegalEntityShippingId, 0) = 0)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM [DBO].[LegalEntityShipping] LS WITH(NOLOCK) WHERE LS.[ShipViaId] = @ShipViaId AND LS.[ShippingAccountInfo] = @ShippingAccountInfo AND LS.[MasterCompanyId] = @MasterCompanyId AND LS.[LegalEntityShippingAddressId] = @LegalEntityShippingAddressId AND LS.[LegalEntityShippingId] <> @LegalEntityShippingId)
			BEGIN

				--If New Default, Reset Old Default To No-Default.
				IF (ISNULL(@IsPrimary, 0) = 1)
				BEGIN
					IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityShipping] WITH(NOLOCK) WHERE [LegalEntityShippingAddressId] = @LegalEntityShippingAddressId AND [IsPrimary] = 1)
					BEGIN				

						UPDATE [DBO].[LegalEntityShipping]
						SET [IsPrimary] = 0,
							[UpdatedDate] = GETUTCDATE(),
							[UpdatedBy] = @UpdatedBy
						WHERE [IsPrimary] = 1 AND [LegalEntityShippingAddressId] = @LegalEntityShippingAddressId;
					
					END
				END
				ELSE
				BEGIN
					-- If No Other Primary Exists, Mark As Primary
					IF NOT EXISTS (SELECT 1 FROM [DBO].[LegalEntityShipping] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimary] = 1 AND [LegalEntityShippingAddressId] = @LegalEntityShippingAddressId AND [IsPrimary] = 1)
					BEGIN
						SET @IsPrimary = 1;
					END
				END				

				-- Insert LegalEntity Ship Via Details
				INSERT INTO [DBO].[LegalEntityShipping] (
					[LegalEntityId], [LegalEntityShippingAddressId], [ShipVia], [ShippingAccountInfo], [Memo], 
					[MasterCompanyId],[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [IsPrimary], [ShipViaId], [ShippingTermsId])	
					VALUES (
					@LegalEntityId, @LegalEntityShippingAddressId, @ShipVia, @ShippingAccountInfo, @Memo, 
					@MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @IsPrimary, @ShipViaId, @ShippingTermsId)

				SET @LegalEntityShippingId = SCOPE_IDENTITY();
			END
			ELSE
			BEGIN
				INSERT INTO #tmpmsg(msg) VALUES ('A Ship Via entry with this Legal Entity, Ship Via and Shipping Account Number already exists.');					
			END
		END
/***************End Save LegalEntity Ship Via Details***************/				
/***************Start Update LegalEntity Ship Via Details.***************/
		ELSE
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM [DBO].[LegalEntityShipping] LS WITH(NOLOCK) WHERE LS.[ShipViaId] = @ShipViaId AND LS.[ShippingAccountInfo] = @ShippingAccountInfo AND LS.[MasterCompanyId] = @MasterCompanyId AND LS.[LegalEntityShippingAddressId] = @LegalEntityShippingAddressId AND LS.[LegalEntityShippingId] <> @LegalEntityShippingId)
			BEGIN
				--IF NEW PRIMARY, RESET OLD PRIMARY TO NO-PRIMARY
				IF (ISNULL(@IsPrimary, 0) = 1)
				BEGIN
					IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityShipping] WITH(NOLOCK) WHERE [LegalEntityShippingAddressId] = @LegalEntityShippingAddressId AND @IsPrimary = 1 AND [LegalEntityShippingId] != @LegalEntityShippingId)
					BEGIN							
					
						UPDATE [DBO].[LegalEntityShipping]
						SET [IsPrimary] = 0,
							[UpdatedBy] = @UpdatedBy,
							[UpdatedDate] = GETUTCDATE()
						WHERE [LegalEntityShippingAddressId] = @LegalEntityShippingAddressId
							AND [IsPrimary] = 1
							AND [LegalEntityShippingId] != @LegalEntityShippingId;					
					END
				END

				UPDATE [DBO].[LegalEntityShipping]
				SET	[ShipVia] = @ShipVia,
					[ShippingAccountinfo] = @ShippingAccountinfo,
					[Memo] = @Memo,
					[IsPrimary] = @IsPrimary,
					[ShipViaId] = @ShipViaId,
					[ShippingTermsId] = @ShippingTermsId,
					[UpdatedBy] = @UpdatedBy,
					[UpdatedDate] = GETUTCDATE()
				WHERE [LegalEntityShippingId] = @LegalEntityShippingId;
			END			
			ELSE
			BEGIN
				INSERT INTO #tmpmsg(msg) VALUES ('A Ship Via entry with this Legal Entity, Ship Via and Shipping Account Number already exists.');					
			END
		END
/***************End Update LegalEntity Ship Via Details***************/		
		IF EXISTS (SELECT 1 FROM #tmpmsg)
		BEGIN
			SELECT msg FROM #tmpmsg;			          
		END
		ELSE
		BEGIN			
			SELECT @LegalEntityShippingId AS LegalEntityShippingId;
		END				
	
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CreateUpdateLegalEntityShipVia'
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