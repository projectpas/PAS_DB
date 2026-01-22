
/*************************************************************           
 ** File:   [USP_GetWorkOrderAddressDetailsByUser]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used retrieve Billing & Shiping Address for Workorder Order    
 ** Purpose:         
 ** Date:   03/05/2021        
          
 ** PARAMETERS:           
 @AddressType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    03/05/2021     Subhash Saliya Created
	2    06/29/2021     Hemant Saliya  Added Transation And Content Managment
     
 EXECUTE [USP_GetWorkOrderAddressDetailsByUser] 2, 97, 'Ship',20199
 EXECUTE [USP_GetWorkOrderAddressDetailsByUser] 2, 13, 'Ship'
 EXECUTE [USP_GetWorkOrderAddressDetailsByUser] 2, 98, 'Bill'
**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_GetWorkOrderAddressDetailsByUser]    
(    
@UserTypeId BIGINT,   
@UserId BIGINT,
@AddressType VARCHAR(20),
@IdList  bigint = 0
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN 
					DECLARE @UserType NVARCHAR(50);

					SELECT @UserType = ModuleName FROM dbo.Module WITH (NOLOCK)  WHERE ModuleId = @UserTypeId;

					IF(@UserType = 'Customer')
					BEGIN
			
						IF(@AddressType = 'Ship')
						BEGIN
							SELECT	adr.AddressId,
									adr.Line1 AS Address1,
									adr.Line2 AS Address2,
									adr.Line3 AS Address3,
									adr.City,
									adr.StateOrProvince,
									adr.PostalCode,
									adr.CountryId,
									c.countries_name,
									lsa.CustomerDomensticShippingId as SiteID,
									lsa.SiteName as SiteName,
									lsa.IsPrimary,
									0 as IsPoOnly,
									lsa.Attention as Attention   
							FROM CustomerDomensticShipping lsa WITH (NOLOCK) 
								JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
								LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
							WHERE lsa.CustomerId = @UserId AND ISNULL(lsa.IsDeleted,0) = 0 AND ISNULL(lsa.IsActive,1) = 1
							UNION 
							SELECT	adr.AddressId,
									adr.Line1 AS Address1,
									adr.Line2 AS Address2,
									adr.Line3 AS Address3,
									adr.City,
									adr.StateOrProvince,
									adr.PostalCode,
									adr.CountryId,
									c.countries_name,
									lsa.CustomerDomensticShippingId as SiteID,
									lsa.SiteName as SiteName,
									lsa.IsPrimary,
									0 as IsPoOnly,
									lsa.Attention as Attention 
							FROM CustomerDomensticShipping lsa WITH (NOLOCK) 
								JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
								LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
							WHERE lsa.CustomerDomensticShippingId = @IdList  and lsa.CustomerId = @UserId
						END

						IF(@AddressType = 'Bill')
						BEGIN
							SELECT	adr.AddressId,
									adr.Line1 AS Address1,
									adr.Line2 AS Address2,
									adr.Line3 AS Address3,
									adr.City,
									adr.StateOrProvince,
									adr.PostalCode,
									adr.CountryId,
									c.countries_name,
									lsa.CustomerBillingAddressId as SiteID,
									lsa.SiteName as SiteName,
									lsa.IsPrimary,
									0 as IsPoOnly,
									lsa.Attention as Attention 
							FROM CustomerBillingAddress lsa WITH (NOLOCK) 
								JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
								LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
							WHERE lsa.CustomerId = @UserId 
								AND ISNULL(lsa.IsDeleted,0) = 0 AND ISNULL(lsa.IsActive,1) = 1
							UNION 
							SELECT	adr.AddressId,
									adr.Line1 AS Address1,
									adr.Line2 AS Address2,
									adr.Line3 AS Address3,
									adr.City,
									adr.StateOrProvince,
									adr.PostalCode,
									adr.CountryId,
									c.countries_name,
									lsa.CustomerBillingAddressId as SiteID,
									lsa.SiteName as SiteName,
									lsa.IsPrimary,
									0 as IsPoOnly,
									lsa.Attention as Attention 
							FROM CustomerBillingAddress lsa WITH (NOLOCK) 
								JOIN dbo.Address adr WITH (NOLOCK)  ON lsa.AddressId = adr.AddressId
								LEFT JOIN dbo.Countries c WITH (NOLOCK)  ON c.countries_id = adr.CountryId
							WHERE lsa.CustomerBillingAddressId = @IdList and lsa.CustomerId = @UserId
						END
					END
				END
			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				PRINT 'HI'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderAddressDetailsByUser' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@UserTypeId, '') + ''', 
													   @Parameter2 = '''+ ISNULL(@UserId, '') + ''', 
													   @Parameter3 = '''+ ISNULL(@AddressType, '') + ''', 
													   @Parameter4 = ' + ISNULL(CAST(@IdList AS varchar(MAX)) ,'') +''
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