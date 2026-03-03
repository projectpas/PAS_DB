/*************************************************************           
 ** File:   [USP_AddUpdateCustomerRfq_PartsBase]           
 ** Author:  Vishal Suthar
 ** Description: This stored procedure is used to store partsbase customer rfq data
 ** Purpose:         
 ** Date:   03/02/2026      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date        Author			Change Description            
 ** --   --------    -------		--------------------------------          
    1    03/02/2026  Vishal Suthar  Created
     
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddUpdateCustomerRfq_PartsBase]
(
    @tbl_CustomerRfqType dbo.CustomerRfqPartsBaseType READONLY,
    @IsFromIls INT NULL,
    @MasterCompanyId INT,
    @CreatedBy VARCHAR(200)
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

    BEGIN TRANSACTION;

    BEGIN TRY

        MERGE INTO [dbo].[CustomerRfq] AS target
        USING @tbl_CustomerRfqType AS source
            ON target.RfqId = source.RfqId
            AND target.IntegrationPortalId = source.IntegrationPortalId
            AND target.MasterCompanyId = @MasterCompanyId

        WHEN MATCHED THEN
            UPDATE SET
                target.RfqCreatedDate     = source.RfqCreatedDate,
                target.Type               = source.Type,
                target.Notes              = source.Notes,

                -- Buyer
                target.BuyerId            = source.BuyerId,
                target.BuyerName          = source.BuyerName,
                target.BuyerCompanyName   = source.BuyerCompanyName,
                target.BuyerCompanyPhone  = source.BuyerCompanyPhone,
                target.BuyerContactId     = source.BuyerContactId,
                target.BuyerAddress       = source.BuyerAddress,
                target.BuyerCity          = source.BuyerCity,
                target.BuyerCountry       = source.BuyerCountry,
                target.BuyerState         = source.BuyerState,
                target.BuyerZip           = source.BuyerZip,
                target.BuyerPhone         = source.BuyerPhone,
                target.BuyerEmail         = source.BuyerEmail,

                -- Seller
                target.SellerId           = source.SellerId,
                target.SellerSiteId       = source.SellerSiteId,
                target.SellerCompanyId    = source.SellerCompanyId,
                target.SellerCompany      = source.SellerCompany,
                target.SellerName         = source.SellerName,
                target.SellerPhone        = source.SellerPhone,
                target.SellerEmail        = source.SellerEmail,
                target.SellerUserName     = source.SellerUserName,

                -- RFQ Header Extra
                target.Guid               = source.Guid,
                target.PriorityCodeId     = source.PriorityCodeId,
                target.PriorityCodeName   = source.PriorityCodeName,
                target.ResponsesDueBy     = source.ResponsesDueBy,
                target.CloseDate          = source.CloseDate,

                -- Line Info (Flattened)
                target.LinePartNumber     = source.LinePartNumber,
                target.LineDescription    = source.LineDescription,
                target.AltPartNumber      = source.AltPartNumber,
                target.Quantity           = source.Quantity,
                target.Condition          = source.Condition,
                target.ConditionCode      = source.ConditionCode,
                target.IsOverhaul         = source.IsOverhaul,
                target.ReqDeliveryDays    = source.ReqDeliveryDays,
                target.SenderInvQuantity  = source.SenderInvQuantity,
                target.SenderListingInv   = source.SenderListingInv,
                target.SupplierPartNumber = source.SupplierPartNumber,
                target.SupplierQuantity   = source.SupplierQuantity,
                target.StatusId           = source.StatusId,
                target.StatusName         = source.StatusName,
                target.RfqItemId          = source.RfqItemId,

                target.IsMRO              = source.IsMRO,
                target.UpdatedBy          = @CreatedBy,
                target.UpdatedDate        = GETUTCDATE()

        WHEN NOT MATCHED BY TARGET THEN
            INSERT
            (
                RfqId, RfqCreatedDate, IntegrationPortalId,
                Type, Notes,
                BuyerId, BuyerName, BuyerCompanyName, BuyerCompanyPhone,
                BuyerContactId, BuyerAddress, BuyerCity, BuyerCountry,
                BuyerState, BuyerZip, BuyerPhone, BuyerEmail,

                SellerId, SellerSiteId, SellerCompanyId,
                SellerCompany, SellerName, SellerPhone,
                SellerEmail, SellerUserName,

                Guid, PriorityCodeId, PriorityCodeName,
                ResponsesDueBy, CloseDate,

                LinePartNumber, LineDescription, AltPartNumber,
                Quantity, Condition, ConditionCode,
                IsOverhaul, ReqDeliveryDays,
                SenderInvQuantity, SenderListingInv,
                SupplierPartNumber, SupplierQuantity,
                StatusId, StatusName, RfqItemId,

                IsMRO,
                MasterCompanyId,
                CreatedBy, UpdatedBy,
                CreatedDate, UpdatedDate,
                IsActive, IsDeleted
            )
            VALUES
            (
                source.RfqId, source.RfqCreatedDate, source.IntegrationPortalId,
                source.Type, source.Notes,
                source.BuyerId, source.BuyerName, source.BuyerCompanyName, source.BuyerCompanyPhone,
                source.BuyerContactId, source.BuyerAddress, source.BuyerCity, source.BuyerCountry,
                source.BuyerState, source.BuyerZip, source.BuyerPhone, source.BuyerEmail,

                source.SellerId, source.SellerSiteId, source.SellerCompanyId,
                source.SellerCompany, source.SellerName, source.SellerPhone,
                source.SellerEmail, source.SellerUserName,

                source.Guid, source.PriorityCodeId, source.PriorityCodeName,
                source.ResponsesDueBy, source.CloseDate,

                source.LinePartNumber, source.LineDescription, source.AltPartNumber,
                source.Quantity, source.Condition, source.ConditionCode,
                source.IsOverhaul, source.ReqDeliveryDays,
                source.SenderInvQuantity, source.SenderListingInv,
                source.SupplierPartNumber, source.SupplierQuantity,
                source.StatusId, source.StatusName, source.RfqItemId,

                source.IsMRO,
                @MasterCompanyId,
                @CreatedBy, @CreatedBy,
                GETUTCDATE(), GETUTCDATE(),
                1, 0
            );

        -- Business Logic
        IF(ISNULL(@IsFromIls,0) = 0)
        BEGIN
            UPDATE rfq
            SET rfq.IsQuote = 1
            FROM [dbo].[CustomerRfq] rfq
            INNER JOIN [CustomerRfqQuote] rfqq 
                ON rfqq.RfqId = rfq.RfqId
            WHERE rfqq.MasterCompanyId = @MasterCompanyId
              AND ISNULL(rfqq.IsDeleted,0) = 0;
        END
        ELSE
        BEGIN
            EXEC DBO.USP_AutoCreateILSQuoteSyc @MasterCompanyId;
        END

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