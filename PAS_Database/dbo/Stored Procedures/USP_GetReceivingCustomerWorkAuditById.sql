
/*************************************************************           
 ** File:   [USP_GetReceivingCustomerWorkAuditById]           
 ** Author:   [Ayushi Patel]
 ** Description: This stored procedure retrieves the history data for Receiving Customer Work Audit.
 ** Date:   [20-03-2025]      
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date             Author		         Change Description            
 ** --   --------         -------		     ----------------------------       
    1    20-03-2025       Ayushi Patel          Created
    2	 20-01-2026       Priyansh Patel  	    Added CSN, TSN, CSO, TSO fields

	USP_GetReceivingCustomerWorkAuditById 4203,229
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetReceivingCustomerWorkAuditById]
    @ReceivingCustomerWorkId BIGINT,
    @EmployeeId BIGINT
AS
BEGIN	
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

        -- Fetch Employee Time Zone
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
            E.EmployeeId = @EmployeeId; -- Get time zone for the specific employee

        BEGIN TRANSACTION;
        BEGIN 
            -- Fetch Receiving Customer Work Audit data
            SELECT 
                stl.ReceivingCustomerWorkId,
                stl.AuditReceivingCustomerWorkId,
                stl.CustomerCode,
                stl.CustomerName,
                stl.EmployeeName,
                stl.ACTailNum,
                con.WorkPhone,
                con.ContactId AS ContactId,
                con.ContactTitle AS ContactTitle,
                (con.FirstName + ' ' + con.LastName) AS ContactFirstName,
                im.PartNumber AS PartNumber,
                ISNULL(stl.IsTimeLife,0) AS IsTimeLife,
                ISNULL(stl.IsExpDate,0) AS IsExpirationDate,
                ISNULL(stl.IsMFGDate,0) IsMFGDate,
                ISNULL(stl.IsCustomerStock,0) IsCustomerStock,
                stl.TimeLifeOrigin,
                stl.TimeLifeDate,
                stl.ReceivingNumber AS ReceivingCustomerNumber,
                stl.TagDate,
                stl.Site AS SiteName,
                stl.Warehouse,
                stl.Location,
                stl.Shelf AS ShelfName,
                stl.Bin AS BinName,
                im.ExpirationDate,
                stl.SerialNumber,
                ISNULL(rp.PartNumber, '') AS RevisedPart,
                im.PartDescription AS PartDescription,
                stl.Quantity,
                (CAST(dbo.ConvertUTCtoLocal(stl.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) AS CreatedDate,
                (CAST(dbo.ConvertUTCtoLocal(stl.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) AS UpdatedDate,
                UPPER(stl.CreatedBy) AS CreatedBy,
                UPPER(stl.UpdatedBy) AS UpdatedBy,
                stl.MFGLotNo AS ManufacturingLotNumber,
                stl.MFGTrace AS ManufacturingTrace,
                stl.ObtainFromTypeId AS ObtainFromType,
                stl.Reference AS CustomerReference,
                stl.Condition AS ConditionType,
                stl.SiteId AS SiteId,
                stl.ShelfId,
                stl.BinId,
                stl.WarehouseId AS WarehouseId,
                stl.LocationId AS LocationId,
                stl.ObtainFrom,
                stl.Owner,
                stl.OwnerTypeId AS OwnerType,
                stl.TraceableTo,
                im.ManufacturerId,
                stl.MFGDate AS ManufacturingDate,
                stl.PartCertificationNumber,
                stl.CertifiedBy,
                stl.TagType,
                stl.TraceableToTypeId AS TraceableToType,
                stl.TimeLifeCyclesId,
                ti.*,
                im.ItemTypeId,
                stl.ManufacturerName,
                stl.ManagementStructureId,
                stl.Level1,
                stl.Level2,
                stl.Level3,
                stl.Level4,
                stl.CustReqTagType,
                stl.CustReqCertType,
                stl.CSN,
                stl.TSN,
                stl.CSO,
                stl.TSO
            FROM dbo.ReceivingCustomerWorkAudit stl WITH (NOLOCK)
            INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON stl.ItemMasterId = im.ItemMasterId
            LEFT JOIN dbo.CustomerContact cc WITH (NOLOCK) ON stl.CustomerContactId = cc.CustomerContactId
            LEFT JOIN dbo.Contact con WITH (NOLOCK) ON cc.ContactId = con.ContactId
            LEFT JOIN dbo.TimeLife ti WITH (NOLOCK) ON stl.TimeLifeCyclesId = ti.TimeLifeCyclesId
            LEFT JOIN dbo.ItemMaster rp WITH (NOLOCK) ON stl.RevisePartId = rp.ItemMasterId
            WHERE stl.ReceivingCustomerWorkId = @ReceivingCustomerWorkId
            ORDER BY stl.AuditReceivingCustomerWorkId DESC;
        END
        COMMIT TRANSACTION;
    
    END TRY    
    BEGIN CATCH      
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME();
        DECLARE @AdhocComments VARCHAR(150) = 'USP_GetReceivingCustomerWorkAuditById';
        DECLARE @ProcedureParameters VARCHAR(3000) = '@ReceivingCustomerWorkId = ' + CAST(ISNULL(@ReceivingCustomerWorkId, '') AS VARCHAR);
        DECLARE @ApplicationName VARCHAR(100) = 'PAS';

        -- Log Exception
        EXEC spLogException 
             @DatabaseName = @DatabaseName,
             @AdhocComments = @AdhocComments,
             @ProcedureParameters = @ProcedureParameters,
             @ApplicationName = @ApplicationName,
             @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected error occurred. Please contact support with error number: %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END;