/*******************************************************************************************
 ** File:   [USP_GetVendorShipVia]          
 ** Author:  Ayushi Patel
 ** Description: Returns Vendor Ship Via History .
 ** Purpose:         
 ** Date:   08/05/2025      
          
 ** PARAMETERS: 
    @VendorShippingId BIGINT,
    @EmployeeId BIGINT
         
 ** RETURN VALUE:          
 *******************************************************************************************           
 ** Change History           
 *******************************************************************************************           
 ** PR   Date         Author		        Change Description            
 ** --   --------     -------		    --------------------------------          
    1    08/05/2025  Ayushi Patel	    Created
     
-- EXEC USP_GetVendorShipVia 4730 , 2
********************************************************************************************/
CREATE   PROCEDURE USP_GetVendorShipVia 
    @VendorShippingId BIGINT,
    @EmployeeId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY
    DECLARE @CurrntEmpTimeZoneDesc NVARCHAR(100);

    SELECT 
						@CurrntEmpTimeZoneDesc = COALESCE(
							ETZ.[Description],  -- Prefer Employee's TimeZone description if available
							LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
						)
					FROM 
						dbo.Employee E WITH (NOLOCK) 
					LEFT JOIN 
						dbo.TimeZone ETZ WITH (NOLOCK) 
						ON E.TimeZoneId = ETZ.TimeZoneId
					LEFT JOIN 
						dbo.LegalEntity LE WITH (NOLOCK) 
						ON E.LegalEntityId = LE.LegalEntityId
					LEFT JOIN 
						dbo.TimeZone LTZ WITH (NOLOCK) 
						ON LE.TimeZoneId = LTZ.TimeZoneId
					WHERE 
						E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

    SELECT 
        sv.ShippingViaId AS ShipViaId,
        sv.Name AS ShipViaName,
        ISNULL(c.ShippingTermsId, 0) AS ShippingTermsId,
        st.Name AS ShippingTerms,
        c.CreatedBy,
        c.UpdatedBy,
		case when CAST(c.CreatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(c.CreatedDate, @CurrntEmpTimeZoneDesc) as datetime))end CreatedDate,
		case when CAST(c.UpdatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(c.UpdatedDate, @CurrntEmpTimeZoneDesc) as datetime))end UpdatedDate,
        c.Memo,
        c.ShipVia,
        c.ShippingId,
        c.ShippingAccountinfo,
        c.ShippingURL,
        c.MasterCompanyId,
        ISNULL(c.IsActive,0) AS IsActive,
        ISNULL(c.IsPrimary,0) AS IsPrimary,
        ISNULL(c.IsDeleted,0) AS IsDeleted
    FROM DBO.VendorShippingAudit c WITH (NOLOCK)
    INNER JOIN DBO.ShippingVia sv WITH (NOLOCK) ON c.ShipViaId = sv.ShippingViaId
    LEFT JOIN DBO.ShippingTerms st WITH (NOLOCK) ON c.ShippingTermsId = st.ShippingTermsId
    WHERE c.VendorShippingId = @VendorShippingId
    ORDER BY c.UpdatedDate DESC;
	END TRY
 BEGIN CATCH
   DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorShipVia'
            , @ProcedureParameters VARCHAR(3000)  = ''  
            , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
            exec spLogException   
                    @DatabaseName   = @DatabaseName  
                    , @AdhocComments   = @AdhocComments  
                    , @ProcedureParameters  = @ProcedureParameters  
                    , @ApplicationName   =  @ApplicationName  
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;  
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
            RETURN(1);  
    END CATCH   
END;