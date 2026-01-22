/*************************************************************           
 ** File:  [USP_GetAllShipViaDetails]  
 ** Author:   Ayushi Patel
 ** Description: Get All Ship Via Details
 ** Purpose:         
 ** Date:   04-07-2025
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR     Date         Author		     	Change Description            
 ** --    --------     -------			-------------------------------          
    1     04-07-2025   Ayushi Patel		Created

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetAllShipViaDetails]
    @Selectedrow BIGINT,
    @IsDeleted BIT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT 
            vsa.SiteName,
            vs.VendorShippingId,
            vs.Memo,
            vs.ShipVia,
            vs.ShippingAccountinfo AS ShippingAccountInfo,
            vs.ShippingURL,
            vs.ShippingId,
            ISNULL(vs.IsActive, 0) AS IsActive,
            vs.VendorId,
            vs.VendorShippingAddressId,
            vs.CreatedDate,
            vs.UpdatedDate,
            ISNULL(vs.IsPrimary, 0) AS IsPrimary,
            sv.ShippingViaId AS ShipViaId,
            sv.Name AS ShipViaName,
            ISNULL(vs.ShippingTermsId, 0) AS ShippingTermsId,
            st.Name AS ShippingTerms,
            vs.CreatedBy,
            vs.UpdatedBy,
            ISNULL(vs.IsDeleted , 0) AS IsDeleted
        FROM dbo.VendorShipping vs WITH (NOLOCK)
        LEFT JOIN dbo.ShippingVia sv WITH (NOLOCK) ON vs.ShipViaId = sv.ShippingViaId
        LEFT JOIN dbo.ShippingTerms st WITH (NOLOCK) ON vs.ShippingTermsId = st.ShippingTermsId
        INNER JOIN dbo.VendorShippingAddress vsa WITH (NOLOCK) ON vsa.VendorShippingAddressId = @Selectedrow
        WHERE vs.VendorShippingAddressId = @Selectedrow
          AND vs.IsDeleted = @IsDeleted
    END TRY
    BEGIN CATCH
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_GetAllShipViaDetails' 
            , @ProcedureParameters VARCHAR(3000)  = ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName			= @DatabaseName
                    , @AdhocComments			= @AdhocComments
                    , @ProcedureParameters		= @ProcedureParameters
                    , @ApplicationName			=  @ApplicationName
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
    END CATCH
END