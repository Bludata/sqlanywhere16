-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
CREATE OR REPLACE FUNCTION "DBA"."simplify_linestring"( 
	ls ST_LineString, toler double )
RETURNS ST_LineString
/*
    simplify_linestring takes a ST_LineString and removes any superfluous
    points within tolerance (toler).
    The linestring must use a planar spatial reference system, and
    the tolerance must be specified in default linear units of measure for
    the spatial reference system.
    WARNING: THE OUTPUT LINESTRING MAY NOT BE SIMPLE (ST_IsSimple returns 0)
    EVEN IF THE INPUT LINESTRING IS SIMPLE.

    Based on the Ramer-Douglas-Peucker algorithm:
        http://en.wikipedia.org/wiki/Ramer-Douglas-Peucker_algorithm
*/
BEGIN
    -- Variable declarations
    DECLARE @leftp INTEGER;                 -- left point id
    DECLARE @leftp_geo ST_Point;            -- left point geometry
    DECLARE @rightp INTEGER;                -- right point id
    DECLARE @rightp_geo ST_Point;           -- right point geometry
    DECLARE @highp INTEGER;                 -- high point id
    DECLARE @maxStack INTEGER = 0;          -- highest stack pkey
    DECLARE @linest ST_Geometry;            -- linestring from left & right
    DECLARE @maxDist DOUBLE = 0;            -- the maximum distance from @linest
    DECLARE @res ST_LineString;             -- Simplified linestring
    
    DECLARE LOCAL TEMPORARY TABLE #lst( 
	    id INT PRIMARY KEY, 
	    geom ST_Point ) NOT TRANSACTIONAL;
    DECLARE LOCAL TEMPORARY TABLE #stack(
	    pkey INT PRIMARY KEY,
	    leftp INT,
	    rightp INT ) NOT TRANSACTIONAL;

    -- Decompose
    INSERT INTO #lst SELECT row_num, ls.ST_PointN( row_num )
		     FROM sa_rowgenerator( 1, ls.ST_NumPoints() );

    /*
        Build the stack.
        The #stack will contain things-to-do.
        It has one col primary key, one representing
        the id of the left point, and one representing
        the id of the right point.
    */

    -- Initialize first values in the stack.
    INSERT INTO #stack SELECT 1, MIN(id),MAX(id) FROM #lst;
    SET @maxStack = @maxStack + 1;

    -- The simplification
    -- If the stack is empty, there's nothing to do
    WHILE @maxStack != 0 LOOP

        -- gather the top element from the stack then delete it        
        SELECT leftp, rightp 
            INTO @leftp, @rightp
            FROM #stack
            WHERE pkey = @maxStack;
        DELETE FROM #stack WHERE pkey = @maxStack;
        SET @maxStack = @maxStack - 1;

        -- Gather the left and right points
        SELECT geom INTO @leftp_geo FROM #lst WHERE id = @leftp;
        SELECT geom INTO @rightp_geo FROM #lst WHERE id = @rightp;

        /*
            Create an ST_LineString from the points
            If @leftpy and @rightpy are equal, we make
            a point instead (this will not affect 
            calculations).
        */
        IF @leftp_geo.ST_Intersects(@rightp_geo) = 1 THEN
            SET @linest = @leftp_geo;
        ELSE
            SET @linest = 
                NEW ST_LineString(
                    @leftp_geo,
                    @rightp_geo
                );
        END IF;

        /*
            Go through each point between the left and right. Find
            the one the greatest distance away from @linest
        */
        SET @maxDist = 0;
	SELECT FIRST @linest.ST_Distance( geom ) as dist, id
	    INTO @maxDist, @highp
            FROM #lst WHERE id > @leftp AND id < @rightp
	    ORDER BY dist DESC;

        /*
            If the furthest distance is greater than the tolerance,
            we want to keep @highp, then simplify off each side of
            it (add @leftp-@highp, @highp-@rightp to the #stack).
	    If a side of @highp doesn't have any intermediate points,
	    it cannot be further simplified, so don't add it to #stack.

            If the furthest distance is less than or equal to
            tolerance, we can safely delete all points between
            @leftp-@rightp from the #lst
        */
        IF @maxDist > toler THEN

	    IF @highp - @leftp > 1 THEN
		INSERT INTO #stack VALUES (
		    @maxStack + 1,
		    @leftp,
		    @highp);
		SET @maxStack = @maxStack + 1;
	    END IF;
	    IF @rightp - @highp > 1 THEN 
		INSERT INTO #stack VALUES (
		    @maxStack + 1,
		    @highp,
		    @rightp);
		SET @maxStack = @maxStack + 1;
	    END IF;

        ELSE

            DELETE FROM #lst WHERE id > @leftp AND id < @rightp;

        END IF;

    END LOOP; -- End simplification

    -- recompose
    SELECT ST_LineString::ST_LineStringAggr( geom ORDER BY id )
        INTO @res
        FROM #lst;

    -- return
    RETURN @res;
    
END;
COMMENT ON PROCEDURE "DBA"."simplify_linestring" IS 'Takes an ST_LineString object and simplifies it, removing any superfluous points within tolerance';

CREATE OR REPLACE FUNCTION "DBA"."simplify_polygon"(p ST_Polygon, toler double)
RETURNS ST_Polygon
BEGIN
    DECLARE @ret ST_Polygon;
    
    SELECT NEW ST_Polygon(
                ST_MultiLineString::ST_MultiLineStringAggr(
                                       simplify_linestring( d.ls, toler ) 
				       ORDER BY rn ) )
    INTO @ret
    FROM ( SELECT p.ST_ExteriorRing() ls, 0 rn
           UNION ALL SELECT p.ST_InteriorRingN( row_num ) ls, row_num rn
	   FROM sa_rowgenerator( 1, p.ST_NumInteriorRing() ) ) d;
    RETURN @ret;
END;
COMMENT ON PROCEDURE "DBA"."simplify_polygon" IS 'Takes an ST_Polygon object and simplifies it, removing any superfluous points within tolerance';

/*
    Implement the equivalent of the geom.ST_Simplify( toler ) method.
    The geometry must use a planar spatial reference system, and
    the tolerance must be specified in default linear units of measure for
    the spatial reference system.
    WARNING: THE OUTPUT GEOMETRY MAY NOT BE VALID (ST_IsValid returns 0)
    EVEN IF THE INPUT LINESTRING IS VALID.
*/    
CREATE OR REPLACE FUNCTION "DBA"."simplify_geometry"( 
	g ST_Geometry, toler double)
RETURNS ST_Geometry
BEGIN
    DECLARE @ret ST_Geometry;
    
    CASE g.ST_GeometryType()
    WHEN 'ST_MultiPolygon' THEN
	SELECT ST_MultiPolygon::ST_MultiPolygonAggr( 
		simplify_polygon( TREAT( TREAT( g AS ST_MultiPolygon )
				    .ST_GeometryN( row_num ) AS ST_Polygon ), 
				  toler ) 
			    ORDER BY row_num )
	       INTO @ret
	       FROM sa_rowgenerator( 1, TREAT( g AS ST_MultiPolygon )
					    .ST_NumGeometries() );
    WHEN 'ST_Polygon' THEN
        SET @ret = simplify_polygon( TREAT( g AS ST_Polygon ), toler );
    WHEN 'ST_MultiLineString' THEN
	SELECT ST_MultiLineString::ST_MultiLineStringAggr( 
		simplify_linestring( TREAT( TREAT( g AS ST_MultiLineString )
				    .ST_GeometryN( row_num ) AS ST_LineString ), 
				  toler ) 
			    ORDER BY row_num )
	       INTO @ret
	       FROM sa_rowgenerator( 1, TREAT( g AS ST_MultiLineString )
					    .ST_NumGeometries() );
    WHEN 'ST_LineString' THEN
        SET @ret = simplify_linestring( TREAT( g AS ST_LineString ), toler );
    ELSE
	-- Do not know how to simplify. Return the original geometry.
	SET @ret = g;
    END CASE;
    RETURN @ret;
END;
COMMENT ON PROCEDURE "DBA"."simplify_geometry" IS 'Tries to simplify the ST_Geometry object. Returns either the simplified geometry or the original geometry.';
