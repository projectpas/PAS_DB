﻿
/*************************************************************           
 ** File:  [RPT_PrintPurchaseVendorDataById]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to Get Print Vendor Data By VendorId
 ** Purpose:         
 ** Date:   09/03/2023      
          
 ** PARAMETERS: @VendorId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/03/2023  Amit Ghediya    Created
     
-- EXEC RPT_PrintPurchaseVendorDataById 7
************************************************************************/
CREATE   PROCEDURE [dbo].[RPT_PrintPurchaseVendorDataById]
@VendorId BIGINT,
@PurchaseOrderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	

		SELECT VN.[VendorId],
			   VN.[VendorName],
			   VN.[VendorCode],
			   --VN.[VendorEmail],
			   VN.[VendorPhone],
			   VN.[VendorPhoneExt],
			  -- (Upper(AD.[Line1]) +'<br/>' +
					--CASE WHEN ISNULL(AD.[Line2],'') != '' THEN Upper(AD.[Line2] )+'<br/>' ELSE '' END +
					--CASE WHEN ISNULL(AD.[City],'') != '' THEN Upper(AD.[City]) ELSE ''END +
					--CASE WHEN ISNULL(AD.[StateOrProvince],'') != '' THEN ' '+ Upper(AD.[StateOrProvince]) ELSE ''END +
					--CASE WHEN ISNULL(AD.[PostalCode],'') != '' THEN ','+ Upper(AD.[PostalCode])+'<br/>'ELSE ''END +
					--CASE WHEN ISNULL(CO.[countries_name],'') != '' THEN ' '+ Upper(CO.[countries_name])+'<br/>'ELSE ''END +
					--CASE WHEN ISNULL(VN.[VendorPhone],'') != '' THEN Upper(VN.[VendorPhone])+'<br/>'ELSE ''END + 
					--CASE WHEN ISNULL(PO.[VendorContactEmail],'') != '' THEN Upper(PO.[VendorContactEmail])+'<br/>'ELSE ''END
					--) MergedAddress
					--,
				MergedAddress1 = (SELECT dbo.ValidatePDFAddress(AD.[Line1],AD.[Line2],NULL,AD.[City],AD.[StateOrProvince],AD.[PostalCode],CO.[countries_name],VN.[VendorPhone],NULL,PO.[VendorContactEmail])),
					
			   AD.[Line1],
			   AD.[Line2],
			   AD.[City],
			   AD.[StateOrProvince],
			   AD.[PostalCode],
			   CO.[countries_name],
			   CO.[countries_id],
			   CU.[Code],
			   PO.[VendorContactEmail] AS 'VendorEmail'
		FROM [DBO].[Vendor] VN WITH (NOLOCK)
		LEFT JOIN [DBO].[PurchaseOrder] PO WITH (NOLOCK) ON PO.PurchaseOrderId = @PurchaseOrderId
		LEFT JOIN [DBO].[Address] AD WITH (NOLOCK) ON VN.AddressId = AD.AddressId
		LEFT JOIN [DBO].[Countries] CO WITH (NOLOCK) ON AD.CountryId = CO.countries_id
		LEFT JOIN [DBO].[Currency] CU WITH (NOLOCK) ON VN.CurrencyId = CU.CurrencyId
		WHERE VN.VendorId = @VendorId;		

  END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'RPT_PrintPurchaseVendorDataById' 
        ,@ProcedureParameters VARCHAR(3000) = '@VendorId = ''' + CAST(ISNULL(@VendorId, '') AS varchar(100))			   
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