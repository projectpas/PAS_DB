/*************************************************************           
 ** File:   [UpdateReceivingCustomerColumnsWithId]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Item Master List for Auto complete Dropdown List    
 ** Purpose:         
 ** Date:   12/30/2020        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    12/30/2020   Hemant Saliya		Created
	2    07/09/2020   Hemant Saliya		Updated SQL Standards
	3    06/04/2020   Devendra Shekh	removal reason update issue resolved
	4    13/09/2024   Moin Bloch	    WorkScope makes left join from inner join
     
--EXEC [UpdateReceivingCustomerColumnsWithId] 5
**************************************************************/

CREATE   PROCEDURE [dbo].[UpdateReceivingCustomerColumnsWithId]
	@ReceivingCustomerWorkId int
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @ManagmnetStructureId AS BIGINT
	DECLARE @stocklineid AS BIGINT
	DECLARE @Level1 AS varchar(200)
	DECLARE @Level2 AS varchar(200)
	DECLARE @Level3 AS varchar(200)
	DECLARE @Level4 AS varchar(200)

	SELECT @ManagmnetStructureId = ManagementStructureId FROM [dbo].[ReceivingCustomerWork] WITH(NOLOCK) WHERE ReceivingCustomerWorkId = @ReceivingCustomerWorkId
	SELECT @stocklineid = StockLineId FROM [dbo].[ReceivingCustomerWork] WITH(NOLOCK) WHERE ReceivingCustomerWorkId = @ReceivingCustomerWorkId
	

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				EXEC dbo.GetMSNameandCode @ManagmnetStructureId,
				 @Level1 = @Level1 OUTPUT,
				 @Level2 = @Level2 OUTPUT,
				 @Level3 = @Level3 OUTPUT,
				 @Level4 = @Level4 OUTPUT

				UPDATE RCW SET 
					RCW.Level1 = @Level1,
					RCW.Level2 = @Level2,
					RCW.Level3 = @Level3,
					RCW.Level4 = @Level4,
					RCW.EmployeeName = E.FirstName + ' ' + E.LastName,
					RCW.CustomerName = c.Name,
					RCW.CustomerCode = c.CustomerCode,
					--RCW.TaggedBy =  EmpTb.FirstName + ' ' + EmpTb.LastName,
					RCW.InspectedBy =  EmpIb.FirstName + ' ' + EmpIb.LastName,
					RCW.ManufacturerName = MF.Name,
					RCW.RevisePartId = IM.RevisedPartId,
					RCW.PartNumber = IM.PartNumber,
					RCW.WorkScope = WS.WorkScopeCode,
					RCW.Condition = CN.Description,
					RCW.Site = S.Name,
					RCW.Warehouse = W.Name,
					RCW.Location = L.Name,
					RCW.Shelf = SL.Name,
					RCW.Bin = B.Name,
					TaggedBy = CASE WHEN RCW.TaggedByType = 1 THEN TAGCUST.[Name] 
									WHEN RCW.TaggedByType = 2 THEN TAGVEN.VendorName
									WHEN RCW.TaggedByType = 9 THEN TAGCOM.[Name]	
									ELSE RCW.TaggedBy
								 END,
					RCW.TaggedByTypeName = (SELECT ModuleName FROM dbo.Module WITH(NOLOCK) WHERE Moduleid = RCW.TaggedByType),
					CertifiedBy =  CASE WHEN RCW.CertifiedTypeId = 1 THEN CERCUST.[Name] 
										WHEN RCW.CertifiedTypeId = 2 THEN CERVEN.VendorName
										WHEN RCW.CertifiedTypeId = 9 THEN CERCOM.[Name]	
										ELSE RCW.CertifiedBy END,
					RCW.CertifiedType = (SELECT ModuleName FROM dbo.Module WITH(NOLOCK) Where Moduleid = RCW.CertifiedTypeId),
					RCW.TagType = TT.[Name],
					RCW.RemovalReasons= tr.Reason,
					RCW.CustReqTagType = RTT.[Name]

				FROM [dbo].[ReceivingCustomerWork] RCW WITH(NOLOCK)
					INNER JOIN [dbo].[Employee] E WITH(NOLOCK) ON RCW.EmployeeId = E.EmployeeId
					INNER JOIN [dbo].[Customer] C WITH(NOLOCK) ON RCW.CustomerId = C.CustomerId
					INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = RCW.ItemMasterId					 
					INNER JOIN [dbo].[Condition] CN WITH(NOLOCK) ON CN.ConditionId = RCW.ConditionId
					INNER JOIN [dbo].[Site] S WITH(NOLOCK) ON S.SiteId = RCW.SiteId
					 LEFT JOIN [dbo].[WorkScope] WS WITH(NOLOCK) ON WS.WorkScopeId = RCW.WorkScopeId
					 LEFT JOIN [dbo].[Employee] EmpTb WITH(NOLOCK) ON RCW.TaggedById = EmpTb.EmployeeId
					 LEFT JOIN [dbo].[Employee] EmpIb WITH(NOLOCK) ON RCW.InspectedById = EmpTb.EmployeeId
					 LEFT JOIN [dbo].[Warehouse] W WITH(NOLOCK) ON W.WarehouseId = RCW.WarehouseId
					 LEFT JOIN [dbo].[Location] L WITH(NOLOCK) ON L.LocationId = RCW.LocationId
					 LEFT JOIN [dbo].[Shelf] SL WITH(NOLOCK) ON SL.ShelfId = RCW.ShelfId
					 LEFT JOIN [dbo].[Bin] B WITH(NOLOCK) ON B.BinId = RCW.BinId
					 LEFT JOIN [dbo].[Manufacturer] MF WITH(NOLOCK) ON IM.ManufacturerId = MF.ManufacturerId					
					 LEFT JOIN [dbo].[Customer] TAGCUST WITH(NOLOCK) ON TAGCUST.CustomerId = RCW.TaggedById
					 LEFT JOIN [dbo].[Vendor] TAGVEN WITH(NOLOCK) ON TAGVEN.VendorId = RCW.TaggedById
					 LEFT JOIN [dbo].[LegalEntity] TAGCOM WITH(NOLOCK) ON TAGCOM.LegalEntityId = RCW.TaggedById
					 LEFT JOIN [dbo].[Customer] CERCUST WITH(NOLOCK) ON CERCUST.CustomerId = RCW.CertifiedById
					 LEFT JOIN [dbo].[Vendor] CERVEN WITH(NOLOCK) ON CERVEN.VendorId = RCW.CertifiedById
					 LEFT JOIN [dbo].[LegalEntity] CERCOM WITH(NOLOCK) ON CERCOM.LegalEntityId = RCW.CertifiedById
					 LEFT JOIN [dbo].[TagType] TT WITH (NOLOCK) ON TT.TagTypeId = RCW.TagTypeIds
					 LEFT JOIN [dbo].[TeardownReason]  tr WITH (NOLOCK) ON tr.TeardownReasonId = RCW.RemovalReasonId and tr.CommonTeardownTypeId=(SELECT TOP 1 tdt.CommonTeardownTypeId FROM [dbo].[CommonTeardownType] tdt WITH (NOLOCK) WHERE tdt.TearDownCode= 'RemovalReason' AND tdt.MasterCompanyId = RCW.MasterCompanyId)
					 LEFT JOIN [dbo].[TagType] RTT WITH (NOLOCK) ON RTT.TagTypeId = RCW.CustReqTagTypeId

				WHERE RCW.ReceivingCustomerWorkId = @ReceivingCustomerWorkId

				UPDATE SL SET CustomerName= c.Name FROM [dbo].[Stockline] SL WITH(NOLOCK)
					INNER JOIN dbo.Customer C WITH(NOLOCK) ON SL.CustomerId = C.CustomerId 
				WHERE StockLineId=@stocklineid
			END
		COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateReceivingCustomerColumnsWithId' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReceivingCustomerWorkId, '') AS VARCHAR(100))  
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